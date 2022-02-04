package crapp.model;

import sys.FileSystem;
import helper.kits.FileKit;
import anonstruct.AnonStruct;

typedef CrappMigrationData = {
    var database:String;
    var migration:Array<String>;
}

class CrappMigrationDataValidator extends AnonStruct {

    public function new(migrationPath:String) {
        super();

        var migrationItem:AnonStruct = new AnonStruct();
        migrationItem.valueString()
            .refuseNull()
            .refuseEmpty()
            .addValidation(function(value:String):Void {
                var path:String = FileKit.addPath(migrationPath, value);
                if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) {
                    throw 'Migration file ${value} not found.';
                }
        });

        this.propertyString('database')
            .refuseNull()
            .refuseEmpty();

        this.propertyArray('migration')
            .refuseNull()
            .setStruct(migrationItem);

    }

}