package crapp.res.migration;

import node.mysql.Mysql;
import crapp.model.CrappModel.CrappModelDatabase;

class MigrationConnector {

    private var data:CrappModelDatabase;
    private var connection:MysqlConnection;

    public function new(data:CrappModelDatabase) {
        this.data = data;
    }

    inline private function print(message:String):Void Crapp.S.controller.print(1, 'MIGRATION : ${message}');

    public function connect(onConnect:()->Void):Void {
        this.print('Connecting database...');

        this.connection = Mysql.createConnection({
            host : this.data.host,
            user : this.data.user,
            password : this.data.password,
            port : this.data.port,
            charset : 'utf8mb4',
            multipleStatements : true
        });

        this.connection.connect(function(onError:MysqlError):Void {
            if (onError == null) {
                this.print('Database connected!');
                onConnect();
            } else {
                this.print('Database Connection Error: ' + onError.toString());
            }
        });
    }

    public function execute(sql:Array<String>, onResult:()->Void, onError:(message:String)->Void):Void {
        if (sql.length == 0) onResult();
        else {
            var currQuery:String = sql.shift();

            this.query(
                currQuery,
                this.execute.bind(sql, onResult, onError),
                function(message:String):Void this.rollback(onError.bind(message))
            );
        }
    }

    public function getLastMigrationKey(database:String, onResult:(value:String)->Void, onError:(message:String)->Void):Void {
        var query:String = 'SELECT value FROM `${database}`.`crapp_migration` LIMIT 1';

        this.connection.queryResult(query, function(err:MysqlError, r:MysqlResultSet<{value:String}>):Void {
            if (err == null) {
                if (r.hasNext()) onResult(r.next().value);
                else onResult('');
            } else onError(err.message);
        });
    }

    public function killConnector():Void {
        this.connection.end();
    }

    private function rollback(onResult:()->Void):Void {
        this.connection.rollback(function(err:MysqlError):Void {
            onResult();
        });
    }

    private function query(sql:String, onResult:()->Void, onError:(message:String)->Void):Void {
        this.connection.query(
            sql,
            function(err:MysqlError, r:Dynamic, f:Array<MysqlFieldPacket>):Void {
                if (err == null) onResult();
                else onError(err.message);
            }
        );
    }
}
