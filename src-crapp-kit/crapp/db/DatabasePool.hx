package crapp.db;

import haxe.crypto.Sha256;
import helper.cache.InMemoryCache;
import haxe.Timer;
import node.mysql.Mysql;
import node.mysql.Mysql.MysqlConnectionPoolOptions;
import node.mysql.Mysql.MysqlConnectionPool;
import node.mysql.Mysql.MysqlResultSet;
import node.mysql.Mysql.MysqlError;
import helper.maker.QueryMaker;
import node.mysql.Mysql.MysqlConnection;
import crapp.model.CrappDatabaseRequestData;
import helper.kits.StringKit;
import haxe.ds.StringMap;
import crapp.model.CrappModel.CrappModelDatabase;

class DatabasePool {

    static public var ERROR_INVALID_TICKET:String = 'ER_CRAPP_INVALID_TICKET';
    static public var ERROR_CONNECTION_TIMEOUT:String = 'ER_CRAPP_CONNECTION_TIMEOUT';

    private var pool:MysqlConnectionPool;

    private var map:StringMap<DatabasePoolConnection>;
    private var model:CrappModelDatabase;
    private var cache:StringMap<DatabasePoolCache>;

    public function new(model:CrappModelDatabase) {
        this.model = model;

        this.map = new StringMap<DatabasePoolConnection>();
        this.cache = new StringMap<DatabasePoolCache>();
    }

    private function createPool():Void {
        if (this.pool == null) {
            var options:MysqlConnectionPoolOptions = {
                connectionLimit : this.model.max_connections == null ? 12 : this.model.max_connections,
                host : this.model.host,
                user : this.model.user,
                password : this.model.password,
                port : this.model.port,
                charset : 'utf8mb4'
            }

            this.pool = Mysql.createPool(options);
        }
    }

    public function close():Void {
        for (ticket in this.map.keys()) this.killTicket(ticket, true);
        this.pool.end();
    }

    public function closeTicket(ticket:String, ?callback:()->Void, ?rollback:Bool):Void {
        this.killTicket(ticket, false, callback, rollback);
    }

    public function getTicket(callback:(ticket:String)->Void, ticketExpirationTime:Int = 60000):Void {
        var ticket:String = StringKit.generateRandomHex(32);
        var ticketTimedOut:Bool = false;
        var ticketTimer:Timer;

        if (this.model.acquire_timeout != null) {
            ticketTimer = haxe.Timer.delay(function():Void {
                ticketTimedOut = true;
                callback(ticket);

            }, this.model.acquire_timeout);
        }

        this.createPool();
        this.pool.getConnection(
            function(connError:MysqlError, conn:MysqlConnection):Void {

                if (ticketTimer != null) {
                    ticketTimer.stop();
                    ticketTimer.run = null;
                    ticketTimer = null;
                }

                if (connError == null) {
                    if (ticketTimedOut) conn.release();
                    else {

                        this.runSimpleQuery(conn, 'SET SESSION group_concat_max_len = 1000000', function(err_a:Bool):Void {
                            this.runSimpleQuery(conn, 'START TRANSACTION', function(err_b:Bool):Void {
                                if (err_a || err_b) {
                                    conn.release();
                                    callback(ticket);
                                } else {
                                    var poolConn:DatabasePoolConnection = {
                                        conn : conn,
                                        timer : haxe.Timer.delay(this.killTicket.bind(ticket, true), ticketExpirationTime)
                                    }

                                    this.map.set(ticket, poolConn);
                                    callback(ticket);
                                }
                            });
                        });
                    }

                } else {
                    if (!ticketTimedOut) callback(ticket);
                }
            }
        );

    }

    private function runSimpleQuery(conn:MysqlConnection, query:String, cb:(err:Bool)->Void) {
        conn.queryResult(query, function(err:MysqlError, result:MysqlResultSet<Dynamic>):Void {
            if (err != null) cb(true);
            else cb(false);
        });
    }

    private function killTicket(ticket:String, destroyConnection:Bool, ?callback:()->Void, ?rollback:Bool):Void {
        if (this.map.exists(ticket)) {
            var poolConn:DatabasePoolConnection = this.map.get(ticket);
            poolConn.timer.stop();

            if (destroyConnection) {
                poolConn.conn.destroy();
                if (callback != null) haxe.Timer.delay(callback, 0);
            } else {
                poolConn.conn.queryResult(rollback ? 'ROLLBACK' : 'COMMIT', function(err:MysqlError, result:MysqlResultSet<Dynamic>):Void {
                    poolConn.conn.release();
                    if (callback != null) callback();
                });
            }

            this.map.remove(ticket);
        }
    }

    public function isOpen(ticket:String):Bool return this.map.exists(ticket);

    public function query<T>(ticket:String, request:CrappDatabaseRequestData, onSuccess:(data:DatabaseSuccess<T>)->Void, ?onError:(err:DatabaseError)->Void):Void {
        if (!this.isOpen(ticket)) {
            haxe.Timer.delay(function():Void {
                if (onError != null) onError(
                    this.generateError(ticket, request.query, ERROR_INVALID_TICKET, request.error, 'Invalid database ticket.')
                );
            }, 0);

        } else {
            var conn:MysqlConnection = this.map.get(ticket).conn;
            var sanitizedQuery:String = QueryMaker.make(request.query, request.data, conn.escape);

            if (request.cache) {
                var cache:DatabaseSuccess<T> = this.restoreCache(sanitizedQuery);
                if (cache != null){
                    haxe.Timer.delay(onSuccess.bind(cache), 0);
                    return;
                }
            }

            var connectionKilled:Bool = false;
            var queryFinished:Bool = false;
            var checkConnectionKilled:()->Void;

            checkConnectionKilled = function():Void {
                if (!queryFinished) {
                    if (this.isOpen(ticket)) haxe.Timer.delay(checkConnectionKilled, 100);
                    else {
                        connectionKilled = true;

                        if (onError != null) onError(
                            this.generateError(ticket, sanitizedQuery, ERROR_CONNECTION_TIMEOUT, request.error, 'Connection killed due overtime.')
                        );
                    }
                }
            }

            conn.queryResult(
                sanitizedQuery,
                function(err:MysqlError, result:MysqlResultSet<T>):Void {
                    if (connectionKilled) return;
                    queryFinished = true;

                    if (err == null) {
                        var resultSuccess:DatabaseSuccess<T> = {
                            hasCreatedSomething : (result.insertId != null && result.insertId > 0),
                            createdId : result.insertId,
                            raw : result,
                            length : result.length
                        }

                        if (request.cache && !resultSuccess.hasCreatedSomething)
                            this.keepCache(sanitizedQuery, resultSuccess, request.cache_timeout);

                        onSuccess(resultSuccess);
                    } else {
                        if (onError != null) onError(
                            this.generateError(ticket, sanitizedQuery, err.code, request.error, err.message)
                        );
                    }
                },
                request.timeout == null
                    ? 50000
                    : request.timeout
            );
        }

    }

    private function keepCache(sql:String, success:DatabaseSuccess<Any>, ?cacheTimeout:Int):Void {
        if (cacheTimeout == null) cacheTimeout = 500;

        var cacheData:DatabasePoolCache;
        var hash:String = Sha256.encode(sql);

        this.killCache(hash);

        var cacheData:DatabasePoolCache = {
            sql : sql,
            result : success,
            timer : haxe.Timer.delay(this.killCache.bind(hash), cacheTimeout)
        }

        this.cache.set(hash, cacheData);
    }

    private function restoreCache<T>(sql:String):DatabaseSuccess<T> {
        var hash:String = Sha256.encode(sql);

        if (this.cache.exists(hash)) {
            var cacheData:DatabasePoolCache = this.cache.get(hash);

            if (cacheData.sql == sql) {
                cacheData.result.raw = cacheData.result.raw.clone();

                return cast cacheData.result;
            }
        }

        return null;
    }

    private function killCache(hash:String):Void {
        if (this.cache.exists(hash)) {
            this.cache.get(hash).timer.stop();
            this.cache.remove(hash);
        }
    }

    inline private function generateError(ticket:String, sql:String, code:String, altMessage:String, message:String):DatabaseError {
        var result:DatabaseError = {
            ticket : ticket,
            query : sql,
            code : code,
            message : altMessage == null
                ? message
                : altMessage
        }

        return result;
    }

}

private typedef DatabasePoolConnection = {
    var conn:MysqlConnection;
    var timer:haxe.Timer;
}

private typedef DatabasePoolCache = {
    var sql:String;
    var result:DatabaseSuccess<Any>;
    var timer:haxe.Timer;
}