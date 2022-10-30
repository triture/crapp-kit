package node.mysql;

import Array;
import sys.db.ResultSet;

@:native("require('mysql')")
extern class Mysql {

    static public function createConnection(options:MysqlConnectionOptions):MysqlConnection;
    static public function createPool(options:MysqlConnectionPoolOptions):MysqlConnectionPool;

    static public function escape(value:String):String;

}

extern class MysqlConnection {

    public function connect(onError:MysqlError->Void):Void;

    // callback = error, results, fields
    @:overload(function(sql:{sql:String, timeout:Int}, callback:MysqlError->Array<Dynamic>->Array<MysqlFieldPacket>->Void):MysqlQuery{})
    public function query(sql:String, callback:MysqlError->Array<Dynamic>->Array<MysqlFieldPacket>->Void):MysqlQuery;

    public function end():Void;

    public function escape(value:String):String;

    public function release():Void;

    public function destroy():Void;

    inline public function queryResult<T>(sql:String, callback:MysqlError->MysqlResultSet<T>->Void, ?timeout:Int):Void {
        this.query(
            {
                sql : sql,
                timeout : timeout
            },
            function(err:MysqlError, r:Dynamic, f:Array<MysqlFieldPacket>):Void {
                if (err == null) {

                    var result:MysqlResultSet<T> = new MysqlResultSet<T>(r, f);
                    callback(null, result);

                } else callback(err, cast []);
            }
        );
    }

    public function beginTransaction(callback:(err:MysqlError)->Void):Void;
    public function commit(callback:(err:MysqlError)->Void):Void;
    public function rollback(callback:(err:MysqlError)->Void):Void;
}

extern class MysqlConnectionPool {

    // callback = error, results, fields
    public function query(sql:String, callback:MysqlError->Array<Dynamic>->Array<MysqlFieldPacket>->Void):MysqlQuery;

    public function escape(value:String):String;

    // callback = error, MysqlConnection
    public function getConnection(callback:MysqlError->MysqlConnection->Void):Void;

    public function end(?callback:(error:MysqlError)->Void):Void;

    inline public function queryResult<T>(sql:String, callback:MysqlError->MysqlResultSet<T>->Void):Void {
        this.query(
            sql,
            function(err:MysqlError, r:Dynamic, f:Array<MysqlFieldPacket>):Void {
                if (err == null) {

                    var result:MysqlResultSet<T> = new MysqlResultSet<T>(r, f);
                    callback(null, result);

                } else callback(err, cast []);
            }
        );
    }
}

extern class MysqlQuery {

    public function on(event:MysqlQueryEventType, callback:Dynamic->Void):Void;

}

extern class MysqlFieldPacket {
    public var catalog:String;
    public var db:String;
    public var table:String;
    public var orgTable:String;
    public var name:String;
    public var orgName:String;
    public var charsetNr:Int;
    public var length:Int;
    public var type:Int;
    public var flags:Int;
    public var decimals:Int;
    public var zeroFill:Bool;
    public var protocol41:Bool;
}

@:enum
abstract MysqlQueryEventType(String) from String to String {
    var ERROR = 'error'; //> callback error
    var FIELDS = 'fields'; //> callbask fields
    var RESULT = 'result'; //> callback row
    var END = 'end'; //> callback null
}

typedef MysqlConnectionOptions = {
    var host:String;
    var user:String;
    var password:String;

    @:optional var port:Int;
    @:optional var database:String;
    @:optional var charset:String;
    @:optional var multipleStatements:Bool;

}


typedef MysqlConnectionPoolOptions = {
    > MysqlConnectionOptions,

    var connectionLimit:Int;
    @:optional var acquireTimeout:Int;
}

extern class MysqlError {

    public var message : String;
    public var name : String;
    public var stack(default,null) : String;

    public var code:String;
    public var fatal:Bool;
    public var sql:String;
    public var sqlState:String;
    public var sqlMessage:String;

    public function toString():String;
}

class MysqlResultSet<T> implements ResultSet {

    private var __r:Dynamic;
    private var __f:Array<MysqlFieldPacket>;
    private var __currentPosition:Int = 0;

    private var __cache_fields:Array<String>;

    @:allow(node.mysql.MysqlConnection.queryResult)
    @:allow(node.mysql.MysqlConnectionPool.queryResult)
    private function new(r:Dynamic, f:Array<MysqlFieldPacket>) {

        this.__r = r;
        this.__f = f;
        this.__currentPosition = -1;

    }

    public var insertId(get, null):Int;
    public var insertIds(get, null):Array<Int>;
    public var affectedRows(get, null):Int;
    public var changedRows(get, null):Int;

    public var length(get, null):Int;
    public var nfields(get, null):Int;

    private function get_insertId():Int return this.__r.insertId;

    private function get_insertIds():Array<Int> {
        var id:Int = this.insertId;
        var result:Array<Int> = [];

        for (i in 0 ... (this.affectedRows - this.changedRows)) result.push(id + i);

        return result;
    }
    private function get_affectedRows():Int return this.__r.affectedRows;
    private function get_changedRows():Int return this.__r.changedRows;

    private function get_length():Int return this.__r.length;
    private function get_nfields():Int return this.__f.length;


    public function hasNext():Bool {
        if (this.length == null || this.length == 0) return false;
        else return this.__currentPosition < (this.length - 1) ;
    }


    public function next():T {
        this.__currentPosition++;
        return this.__r[this.__currentPosition];
    }

    public function results():List<T> {
        var l:List<T> = new List<T>();
        for (i in 0 ... this.__r.length) l.add(this.__r[i]);
        return l;
    }

    public function getResult(n:Int):String return '';
    public function getIntResult(n:Int):Int return 0;
    public function getFloatResult(n:Int):Float return 0;

    public function getFieldsNames():Null<Array<String>> {
        if (this.__f == null) return null;
        else {
            if (this.__cache_fields == null) this.__cache_fields = [for (f in this.__f) f.name];
            return this.__cache_fields.copy();
        }
    }

}