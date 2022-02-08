package crapp.res.migration;

class MigrationResource {

    private var connector:MigrationConnector;
    private var migrationValues:Array<{key:String, sql:String}>;
    private var database:String;

    public function new(database:String, connector:MigrationConnector) {
        this.database = database;
        this.connector = connector;

        this.migrationValues = [];
    }

    inline private function print(message:String):Void Crapp.S.controller.print(1, 'MIGRATION : ${message}');

    public function add(key:String, sql:String):Void this.migrationValues.push({key:key, sql:sql});

    public function execute(onResolve:()->Void, onError:(message:String)->Void):Void {

        this.createMigrationTables(
            this.getLastMigrationKey.bind(
                this.mysql_executePack.bind(_, onResolve, onError),
                onError
            ),
            onError
        );
    }

    private function createMigrationTables(onResult:()->Void, onError:(message:String)->Void):Void {
        var sqls:Array<String> = [];

        sqls.push('SET CHARSET "utf8";',);
        sqls.push('START TRANSACTION;');
        sqls.push('CREATE DATABASE IF NOT EXISTS `${this.database}` /*!40100 DEFAULT CHARACTER SET utf8 */;');
        sqls.push('CREATE TABLE IF NOT EXISTS `${this.database}`.`crapp_migration` (`value` VARCHAR(1024) NOT NULL COLLATE \'utf8_general_ci\')
            COLLATE=\'utf8_general_ci\'
            ENGINE=InnoDB;
        ');
        sqls.push('COMMIT;');

        this.connector.execute(sqls, onResult, onError);
    }

    private function getLastMigrationKey(onResult:(value:String)->Void, onError:(message:String)->Void):Void {
        this.connector.getLastMigrationKey(this.database, onResult, onError);
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
        var sqls:Array<String> = [
            'SET CHARSET "utf8";',
            'START TRANSACTION;',
            sql,
            'DELETE FROM `${this.database}`.`crapp_migration`;',
            'INSERT INTO `${this.database}`.`crapp_migration` (`value`) VALUES ("${key}");',
            'COMMIT;'
        ];

        this.connector.execute(
            sqls,
            this.mysql_executePack.bind(key, onResolve, onError),
            onError
        );
    }

}

