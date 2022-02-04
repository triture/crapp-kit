package crapp.controller;

import node.mysql.Mysql;
import anonstruct.AnonStructError;
import crapp.model.CrappMigrationData;
import sys.io.File;
import sys.FileSystem;
import helper.kits.FileKit;

class MigrationController {

    private var onDone:()->Void;

    private var migrationData:CrappMigrationData;
    private var connection:MysqlConnection;

    public function new() {

    }

    inline private function print(message:String):Void Crapp.S.controller.print(1, 'MIGRATION : ${message}');

    private function done():Void {
        this.print('Migration Done!\n\n');
        this.onDone();
    }

    public function run(onDone:()->Void):Void {
        this.onDone = onDone;

        Crapp.S.controller.print(0, 'Executing CRAPP Migration');
        Crapp.S.controller.print(1, 'Running Migration...');

        this.createDatabaseConnection(
            this.runCrappInternalMigration.bind(
                this.runApplicationMigration.bind(this.done)
            )
        );


    }

    private function runCrappInternalMigration(onResolve:()->Void):Void {
        this.print('Running crapp internal migrations...');

        var migrationPack:MigrationPackage = new MigrationPackage('crapp_log', this.connection);

        migrationPack.add('00001', "
            CREATE DATABASE IF NOT EXISTS `crapp_log` /*!40100 COLLATE 'utf8_general_ci' */;

            CREATE TABLE crapp_log.`service_log` (
                `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
                `situation` ENUM('SUCCESS','ERROR') NOT NULL COLLATE 'utf8_general_ci',
                `host` VARCHAR(1024) NOT NULL COLLATE 'utf8_general_ci',
                `verb` ENUM('GET','POST','DELETE','PUT','OPTION') NOT NULL COLLATE 'utf8_general_ci',
                `route` VARCHAR(4096) NOT NULL COLLATE 'utf8_general_ci',
                `status` SMALLINT(5) UNSIGNED NOT NULL,
                `run_time` SMALLINT(5) UNSIGNED NOT NULL,
                `etag` VARCHAR(256) NOT NULL COLLATE 'utf8_general_ci',
                `ip` VARCHAR(256) NOT NULL COLLATE 'utf8_general_ci',
                `user_agent` VARCHAR(2048) NOT NULL COLLATE 'utf8_general_ci',
                `message` VARCHAR(2048) NULL DEFAULT NULL COLLATE 'utf8_general_ci',
                `debug` MEDIUMBLOB NULL DEFAULT NULL,
                `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`) USING BTREE
            )
            COLLATE='utf8_general_ci'
            ENGINE=InnoDB
            ;
        ");

        migrationPack.execute(onResolve, this.print);
    }

    private function runApplicationMigration(onResolve:()->Void):Void {
        this.print('Running application migrations...');

        if (!this.existMigrationData()) onResolve();
        else {
            if (this.isMigrationDataLoaded()) {
                if (this.migrationData == null || this.migrationData.migration.length == 0) onResolve();
                else {
                    var migrationPack:MigrationPackage = new MigrationPackage(this.migrationData.database, this.connection);

                    for (item in this.migrationData.migration) {
                        migrationPack.add(item, File.getContent(FileKit.addPath(Crapp.S.model.migration_path, item)));
                    }

                    migrationPack.execute(onResolve, this.print);
                }
            }
        }
    }

    private function createDatabaseConnection(onResolve:()->Void):Void {
        this.print('Starting MYSQL connection...');

        this.connection = Mysql.createConnection({
            host : Crapp.S.model.database.host,
            user : Crapp.S.model.database.user,
            password : Crapp.S.model.database.password,
            port : Crapp.S.model.database.port,
            charset : 'utf8mb4',
            multipleStatements : true
        });

        this.connection.connect(function(onError:MysqlError):Void {
            if (onError == null) onResolve();
            else {
                this.print('Mysql Connection Error: ' + onError.toString());
            }
        });
    }

    private function existMigrationData():Bool {
        this.print('Check if migration exists...');

        var path:String = this.getMigrationDriverPath();

        if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) {
            this.print('Migration files not found...');
            return false;
        }

        return true;
    }

    private function isMigrationDataLoaded():Bool {

        var path:String = this.getMigrationDriverPath();
        var jsonString:String = File.getContent(path);

        try {
            this.print('Loading crapp-migration.json...');

            var jsonData:CrappMigrationData = haxe.Json.parse(jsonString);
            var validator:CrappMigrationDataValidator = new CrappMigrationDataValidator(Crapp.S.model.migration_path);

            validator.validate(jsonData);

            this.migrationData = jsonData;
            return true;

        } catch (e:AnonStructError) {
            this.print('Error: ' + e.property + ' - ' + e.errorMessage);

        } catch (e:Dynamic) {
            this.print('Error on loading Migration Data: ' + Std.string(e));

        }

        return false;
    }

    private function getMigrationDriverPath():String {
        var driverFile:String = 'crapp-migration.json';
        var path:String = FileKit.addPath(Crapp.S.model.migration_path, driverFile);

        return path;
    }

}

private class MigrationPackage {

    private var connection:MysqlConnection;
    private var migrationValues:Array<{key:String, sql:String}>;
    private var primaryDatabase:String;

    public function new(primaryDatabase:String, connection:MysqlConnection) {
        this.primaryDatabase = primaryDatabase;
        this.connection = connection;

        this.migrationValues = [];
    }

    inline private function print(message:String):Void Crapp.S.controller.print(1, 'MIGRATION : ${message}');

    public function add(key:String, sql:String):Void this.migrationValues.push({key:key, sql:sql});

    public function execute(onResolve:()->Void, onError:(message:String)->Void):Void {
        this.mysql_doCreateMigrationTable(
            this.mysql_getLastMigrationKey.bind(
                this.mysql_executePack.bind(_, onResolve, onError),
                onError
            ),
            onError
        );
    }

    private function mysql_doCreateMigrationTable(onResolve:()->Void, onError:(message:String)->Void):Void {
        var query:String = '
            CREATE DATABASE IF NOT EXISTS `${this.primaryDatabase}` /*!40100 DEFAULT CHARACTER SET utf8 */;
            CREATE TABLE IF NOT EXISTS `${primaryDatabase}`.`crapp_migration` (
                `value` VARCHAR(1024) NOT NULL COLLATE \'utf8_general_ci\'
            )
            COLLATE=\'utf8_general_ci\'
            ENGINE=InnoDB;
        ';

        this.connection.query(query, function(err:MysqlError, r:Array<Dynamic>, f:Array<MysqlFieldPacket>):Void {
            if (err == null) onResolve();
            else onError(err.message);
        });
    }

    private function mysql_getLastMigrationKey(onResolve:(value:String)->Void, onError:(message:String)->Void):Void {
        var query:String = 'SELECT value FROM `${this.primaryDatabase}`.`crapp_migration` LIMIT 1';

        this.connection.queryResult(query, function(err:MysqlError, r:MysqlResultSet<{value:String}>):Void {
            if (err == null) {
                if (r.hasNext()) onResolve(r.next().value);
                else onResolve('');
            } else onError(err.message);
        });
    }

    private function mysql_executePack(lastKey:String, onResolve:()->Void, onError:(message:String)->Void):Void {
        var keyIndex:Int = -1;

        if (lastKey.length == 0) keyIndex = 0;
        else {
            if (lastKey.length > 0) for (i in 0 ... this.migrationValues.length) {
                if (this.migrationValues[i].key == lastKey) {
                    keyIndex = i + 1;
                    break;
                }
            }
        }

        if (keyIndex == -1) onError('Migration track key not found.');
        else if (keyIndex == this.migrationValues.length) onResolve();
        else {

            if (lastKey.length == 0) this.print('Initial migration on ${this.migrationValues[keyIndex].key}');
            else this.print('Migrating ${lastKey} to ${this.migrationValues[keyIndex].key}');

            this.executeRunner(
                this.migrationValues[keyIndex].key,
                this.migrationValues[keyIndex].sql,
                onResolve,
                onError
            );
        }
        
    }

    private function executeRunner(key:String, sql:String, onResolve:()->Void, onError:(message:String)->Void):Void {
        var runner:MigrationRunner = new MigrationRunner(
            this.primaryDatabase,
            this.connection,
            key,
            sql
        );

        runner.execute(
            this.mysql_executePack.bind(key, onResolve, onError),
            onError
        );
    }

}

private class MigrationRunner {

    private var connection:MysqlConnection;
    private var primaryDatabase:String;

    private var migrationKey:String;
    private var migrationContent:String;

    public function new(
        primaryDatabase:String,
        connection:MysqlConnection,
        migrationKey:String,
        migrationContent:String
    ) {
        this.primaryDatabase = primaryDatabase;
        this.connection = connection;

        this.migrationKey = migrationKey;
        this.migrationContent = migrationContent;
    }

    public function execute(onResult:()->Void, onError:(message:String)->Void):Void {
        this.connection.beginTransaction(
            function(err:MysqlError):Void {
                if (err != null) onError(err.message);
                else {

                    this.query(
                        this.migrationContent,
                        function():Void {

                            this.query(
                                this.getUpdateMigrationInstruction(),
                                this.connection.commit.bind(function(err:MysqlError):Void {
                                    if (err == null) onResult();
                                    else this.rollback(onError.bind(err.message));
                                }),
                                function(message:String):Void {
                                    this.rollback(onError.bind(message));
                                }
                            );

                        },
                        function(message:String):Void this.rollback(onError.bind(message))
                    );
                }
            }
        );

    }

    private function rollback(onResult:()->Void):Void {
        this.connection.rollback(function(err:MysqlError):Void {
            onResult();
        });
    }

    private function query(sql:String, onResolve:()->Void, onError:(message:String)->Void):Void {
        this.connection.query(
            sql,
            function(err:MysqlError, r:Dynamic, f:Array<MysqlFieldPacket>):Void {
                if (err == null) onResolve();
                else {
                    var errMessage:String = err.message;
                    onError(errMessage);
                }
            }
        );
    }

    private function getUpdateMigrationInstruction():String return '
        DELETE FROM `${primaryDatabase}`.`crapp_migration`;
        INSERT INTO `${primaryDatabase}`.`crapp_migration` (`value`) VALUES ("${this.migrationKey}");
    ';
}