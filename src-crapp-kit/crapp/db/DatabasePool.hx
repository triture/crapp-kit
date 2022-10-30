package crapp.db;

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

    public function new(model:CrappModelDatabase) {
        this.model = model;

        this.map = new StringMap<DatabasePoolConnection>();
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

    public function closeTicket(ticket:String, ?callback:()->Void):Void {
        this.killTicket(ticket, false, callback);
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
                        conn.queryResult('START TRANSACTION', function(err:MysqlError, result:MysqlResultSet<Dynamic>):Void {
                            if (err == null) {
                                var poolConn:DatabasePoolConnection = {
                                    conn : conn,
                                    timer : haxe.Timer.delay(this.killTicket.bind(ticket, true), ticketExpirationTime)
                                }

                                this.map.set(ticket, poolConn);
                                callback(ticket);
                            } else {
                                conn.release();
                                callback(ticket);
                            }
                        });
                    }

                } else {
                    if (!ticketTimedOut) callback(ticket);
                }
            }
        );

    }

    private function killTicket(ticket:String, destroyConnection:Bool, ?callback:()->Void):Void {
        if (this.map.exists(ticket)) {
            var poolConn:DatabasePoolConnection = this.map.get(ticket);
            poolConn.timer.stop();

            if (destroyConnection) {
                poolConn.conn.destroy();
                if (callback != null) haxe.Timer.delay(callback, 0);
            } else {
                poolConn.conn.queryResult('COMMIT', function(err:MysqlError, result:MysqlResultSet<Dynamic>):Void {
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
                            raw : result,
                            length : result.length
                        }

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