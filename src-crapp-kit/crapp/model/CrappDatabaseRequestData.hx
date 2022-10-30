package crapp.model;

import anonstruct.AnonStruct;

typedef CrappDatabaseRequestData = {
    var query:String;

    @:optional var data:Dynamic;
    @:optional var cache:Bool;
    @:optional var debug:Bool;
    @:optional var retry_on_deadlock:Int;
    @:optional var error:String;
    @:optional var timeout:Int;
}

class CrappDatabaseRequestDataValidator extends AnonStruct {
    public function new() {
        super();

        this.propertyString('query')
            .refuseNull()
            .refuseEmpty();

        this.propertyObject('data')
            .allowNull();

        this.propertyBool('cache')
            .allowNull();

        this.propertyBool('debug')
            .allowNull();

        this.propertyInt('retry_on_deadlock')
            .allowNull()
            .greaterOrEqualThan(0)
            .lessOrEqualThan(10);

        this.propertyString('error')
            .refuseEmpty()
            .allowNull();

    }
}
