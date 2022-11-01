package crapp.controller;

import helper.kits.StringKit;
import crapp.res.migration.MigrationResource;
import crapp.res.migration.MigrationConnector;
import anonstruct.AnonStructError;
import crapp.model.CrappMigrationData;
import sys.io.File;
import sys.FileSystem;
import helper.kits.FileKit;

class MigrationController {

    private var onDone:()->Void;

    private var migrationData:CrappMigrationData;
    private var connector:MigrationConnector;

    public function new() {

    }

    inline private function print(message:String):Void Crapp.S.controller.print(1, 'MIGRATION : ${message}');

    private function done():Void {
        if (this.connector != null) {
            this.connector.killConnector();
            this.connector = null;
        }

        this.print('Migration Done!\n\n');
        this.onDone();
    }

    public function run(onDone:()->Void):Void {
        this.onDone = onDone;

        Crapp.S.controller.print(0, 'Executing CRAPP Migration');
        Crapp.S.controller.print(1, 'Running Migration...');

        this.connector = new MigrationConnector(Crapp.S.model.database);
        this.connector.connect(function():Void {
            this.runCrappInternalMigration(this.runApplicationMigration.bind(this.done));
        });
    }

    private function runCrappInternalMigration(onResolve:()->Void):Void {
        this.print('Running crapp internal migrations...');

        var migrationPack:MigrationResource = new MigrationResource('crapp_log', this.connector);

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
                    var migrationPack:MigrationResource = new MigrationResource(this.migrationData.database, this.connector);

                    for (item in this.migrationData.migration) {
                        migrationPack.add(item, File.getContent(FileKit.addPath(Crapp.S.model.migration_path, item)));
                    }

                    migrationPack.execute(onResolve, this.print);
                }
            }
        }
    }

    private function existMigrationData():Bool {
        this.print('Check if migration exists...');

        if (StringKit.isEmpty(Crapp.S.model.migration_path)) return false;

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