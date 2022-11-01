package crapp.controller;

import crapp.model.CrappModel.CrappModelDatabase;
import haxe.Timer;
import haxe.crypto.Sha1;
import helper.cache.InMemoryCache;
import crapp.model.CrappDatabaseRequestData;
import helper.kits.DebuggerKit;
import crapp.model.CrappResolve;
import crapp.model.CrappDatabaseResult;
import helper.maker.QueryMaker;
import crapp.service.CrappServiceError;
import node.mysql.Mysql.MysqlConnectionPool;
import node.mysql.Mysql;

class DatabaseController {

    private var model:CrappModelDatabase;
    private var isConnected:Bool;
    private var pool:MysqlConnectionPool;
    private var connectionInitializer:Array<String>;

    public function new(model:CrappModelDatabase) {
        this.model = model;

        var data:MysqlConnectionPoolOptions = {
            connectionLimit : this.model.max_connections == null
                ? 12
                : this.model.max_connections,
            host : this.model.host,
            user : this.model.user,
            password : this.model.password,
            port : this.model.port,
            charset : 'utf8mb4'
        }

        this.connectionInitializer = ['SET SESSION group_concat_max_len = 1000000'];
        this.isConnected = false;

        this.pool = Mysql.createPool(data);
    }

    public function close(callback:(err:MysqlError)->Void):Void this.pool.end(callback);

    public function getInstance(callback:(conn:CrappDatabase)->Void):Void {
        this.pool.getConnection(
            function(connError:MysqlError, conn:MysqlConnection):Void {
                if (connError == null) {
                    this.runMultipleQueries(
                        conn,
                        this.connectionInitializer,
                        function():Void {
                            callback(new CrappDatabase(conn));
                        }
                    );
                }
                else {
                    Sys.println(" --- ");
                    Sys.println(" --- ERROR :: " + connError.message);
                    Sys.println(" --- ");
                    callback(new CrappDatabase(null));
                }
            }
        );
    }

    private function runMultipleQueries(conn:MysqlConnection, queries:Array<String>, cb:()->Void):Void {
        if (queries == null || queries.length == 0) cb();
        else {
            var queriesCopy:Array<String> = queries.copy();

            conn.queryResult(
                queriesCopy.shift(),
                function(queryError:MysqlError, result:MysqlResultSet<Dynamic>):Void {
                    this.runMultipleQueries(conn, queriesCopy, cb);
                }
            );
        }
    }

    public function getConnection(callback:(getConnectionError:MysqlError, conn:MysqlConnection)->Void):Void {
        this.pool.getConnection(callback);
    }

    public function make<T>(query:String, queryData:Dynamic, ?callback:(error:MysqlError, result:MysqlResultSet<T>)->Void):Void {
        this.pool.getConnection(
            function(getConnectionError:MysqlError, conn:MysqlConnection):Void {
                if (getConnectionError == null) {

                    this.runMultipleQueries(conn, this.connectionInitializer, function():Void {
                        QueryMaker.SANITIZE = conn.escape;

                        var finalQuery:String = QueryMaker.make(query, queryData);

                        conn.queryResult(
                            finalQuery,
                            function(queryError:MysqlError, result:MysqlResultSet<T>):Void {
                                conn.release();
                                callback(queryError, result);
                            }
                        );
                    });

                } else {
                    if (callback != null) {
                        callback(getConnectionError, null);
                    } else {
                        throw CrappServiceError.SERVER_ERROR(Std.string(getConnectionError));
                    }
                }
            }
        );
    }

}

class CrappDatabaseCache {

    static public var CACHE_TIME(null, set):Int;

    static private var CACHE:InMemoryCache<Dynamic>;

    static private function HAS_CACHE():Bool return CACHE != null;

    static private function set_CACHE_TIME(value:Int):Int {
        if (CACHE != null) {
            CACHE.reset();
            CACHE = null;
        }

        if (value > 0) CACHE = new InMemoryCache<Dynamic>(value);

        return value;
    }

    static public function KEEP_CACHE<T>(query:String, dataResult:MysqlResultSet<T>):Void {
        if (HAS_CACHE()) {
            if (
                (dataResult.insertId == null || dataResult.insertId == 0) &&
                (dataResult.affectedRows == null || dataResult.affectedRows == 0) &&
                (dataResult.changedRows == null || dataResult.changedRows == 0)
            ) {
                var hash:String = Sha1.encode(query);
                CACHE.add(hash, dataResult);
            }
        }
    }

    static public function GET_CACHE<T>(query:String):MysqlResultSet<T> {
        if (HAS_CACHE()) {
            var hash:String = Sha1.encode(query);
            var data:MysqlResultSet<T> = CACHE.get(hash);

            if (data != null) return CLONE(data);
        }

        return null;
    }

    @:access(node.mysql)
    static private function CLONE<T>(data:MysqlResultSet<T>):MysqlResultSet<T> {
        return new MysqlResultSet<T>(data.__r, data.__f);
    }

}

class CrappDatabase {

    public var hasError(get, null):Bool;
    public var isActive(get, null):Bool;

    private var isInTransation:Bool = false;
    private var conn:MysqlConnection;

    private var leakTimer:Timer;

    @:allow(crapp.controller.DatabaseController)
    private function new(conn:MysqlConnection, ?leakTimeout:Int) {
        this.conn = conn;

        this.leakTimer = Timer.delay(function():Void {
            if (this.conn != null) {
                Sys.println('');
                Sys.println(' !! ');
                Sys.println(' !! DATABASE CONNECTION LEAK !!');
                Sys.println(' !! ');
                Sys.println('');
            }
        }, leakTimeout == null ? 30000 : leakTimeout);
    }

    private function get_hasError():Bool return (this.conn == null);

    private function get_isActive():Bool return this.conn != null;

    public function makeQueries<T>(queries:Array<CrappDatabaseRequestData>, callback:(request:CrappDatabaseRequestData, result:CrappDatabaseResult<T>)->Void, onComplete:()->Void):Void {
        var queriesClone:Array<CrappDatabaseRequestData> = queries.copy();

        var serialCall = null;

        serialCall = function():Void {
            if (queriesClone.length == 0) onComplete();
            else {
                var query:CrappDatabaseRequestData = queriesClone.shift();

                this.makeQuery(
                    query,
                    function(result:CrappDatabaseResult<T>):Void {
                        if (callback != null) callback(query, result);
                        serialCall();
                    }
                );
            }
        }

        serialCall();
    }

    public function makeQuery<T>(query:CrappDatabaseRequestData, ?callback:(result:CrappDatabaseResult<T>)->Void):Void {
        this.make(
            query.query,
            query.data,
            callback,
            query.debug == null ? false : query.debug,
            query.cache == null ? false : query.cache,
            query.retry_on_deadlock == null ? 0 : query.retry_on_deadlock
        );
    }

    public function make<T>(query:String, data:Dynamic, ?callback:(result:CrappDatabaseResult<T>)->Void, debug:Bool = false, cache:Bool = false, retrysOnDeadlock:Int = 0):Void {
        if (this.conn == null) this.resultErrorFromNoExistentConnection(callback);
        else {

            if (debug) DebuggerKit.timeTrack('Time-To-Convert-Query');
            var finalQuery:String = QueryMaker.make(query, data, this.conn.escape);
            if (debug) DebuggerKit.timeTrack('Time-To-Convert-Query');
            if (debug) trace(finalQuery);

            var resultFromCache:MysqlResultSet<T> = CrappDatabaseCache.GET_CACHE(finalQuery);

            if (cache == false || resultFromCache == null) {
                this.conn.queryResult(
                    finalQuery,
                    function(queryError:MysqlError, result:MysqlResultSet<T>):Void {
                        if (queryError == null) {
                            if (cache) CrappDatabaseCache.KEEP_CACHE(finalQuery, result);

                            this.resultSuccess(result, callback);
                        } else {

                            if (this.isLockError(queryError.message) && retrysOnDeadlock > 0 && !this.isInTransation) {
                                trace(' -- deadlock error : RETRY STRATEGY');
                                trace(finalQuery);
                                trace(' -- deadlock error : RETRY STRATEGY');

                                retrysOnDeadlock--;

                                haxe.Timer.delay(
                                    this.make.bind(query, data, callback, debug, cache, retrysOnDeadlock),
                                    (30 + Math.floor(Math.random() * 100))
                                );


                            } else this.resultErrorFromWrongQuery(queryError, callback);
                        }
                    }
                );
            } else {
                haxe.Timer.delay(this.resultSuccess.bind(resultFromCache, callback), 0);
            }
        }
    }

    private function isLockError(message:String):Bool {
        if (
            StringTools.startsWith(message, 'ER_LOCK_DEADLOCK') ||
            StringTools.startsWith(message, 'ER_LOCK_WAIT_TIMEOUT') ||
            StringTools.startsWith(message, 'ER_LOCK_TIMEOUT')
        ) return true;

        return false;
    }

    private function resultSuccess<T>(result:MysqlResultSet<T>, ?callback:(result:CrappDatabaseResult<T>)->Void):Void {
        if (callback != null) {
            var resultData:CrappDatabaseResult<T> = {
                hasError : false,
                errorMessage : '',
                errorCode : '',
                result : result,

                hasCreatedSomething : (result.insertId != null && result.insertId > 0),
                createdId : result.insertId,
                length : result.length
            }

            callback(resultData);
        }
    }

    private function resultErrorFromWrongQuery<T>(queryError:MysqlError, ?callback:(result:CrappDatabaseResult<T>)->Void):Void {
        if (callback != null) {
            var resultData:CrappDatabaseResult<T> = {
                hasError : true,
                errorMessage : queryError.message,
                errorCode : queryError.code,
                result : null,
                hasCreatedSomething : false,
                createdId : 0,
                length : 0
            }

            callback(resultData);
        }
    }

    private function resultErrorFromNoExistentConnection<T>(?callback:(result:CrappDatabaseResult<T>)->Void):Void {
        if (callback != null) {
            var resultData:CrappDatabaseResult<T> = {
                hasError : true,
                errorMessage : 'Conexão interrompida com o banco de dados.',
                errorCode : '',
                result : null,
                hasCreatedSomething : false,
                createdId : 0,
                length : 0
            }

            callback(resultData);
        }
    }

    public function kill():Void {
        if (this.conn != null) {
            this.conn.release();
            this.conn = null;
        }
    }

    public function startTransaction(onResolve:CrappResolve, onError:CrappResolve):Void {
        if (this.isInTransation) onResolve();
        else {
            this.make('START TRANSACTION', null, function(result:CrappDatabaseResult<Dynamic>):Void {
                if (result.hasError) onError();
                else {
                    this.isInTransation = true;
                    onResolve();
                }
            });
        }
    }

    public function commitTransaction(onResolve:CrappResolve, onError:CrappResolve):Void {
        if (!this.isInTransation) onResolve();
        else {
            this.make('COMMIT', null, function(result:CrappDatabaseResult<Dynamic>):Void {
                if (result.hasError) onError();
                else {
                    this.isInTransation = false;
                    onResolve();
                }
            });
        }
    }

    public function rollbackTransaction(onResolve:CrappResolve, onError:CrappResolve):Void {
        if (!this.isInTransation) onResolve();
        else {
            this.make('ROLLBACK', null, function(result:CrappDatabaseResult<Dynamic>):Void {
                if (result.hasError) onError();
                else {
                    this.isInTransation = false;
                    onResolve();
                }
            });
        }
    }

    public function makePersistentConnection():Void {
        if (this.leakTimer != null) {
            this.leakTimer.stop();
            this.leakTimer.run = null;
            this.leakTimer = null;
        }
    }

}