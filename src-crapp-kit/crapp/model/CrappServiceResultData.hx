package crapp.model;

import anonstruct.AnonStruct;
import crapp.model.CrappServiceResultPage.CrappServiceResultPageValidator;

typedef CrappServiceResultData = {

    var host:String;
    var endpoint:String;
    var data:Dynamic;
    var error:Bool;

    @:optional var page:CrappServiceResultPage;
    @:optional var data_error:CrappServiceErrorData;
}

class CrappServiceResultDataValidator extends AnonStruct {

    public function new(?dataValidator:Class<AnonStruct>, isDataArray:Bool = false) {
        super();

        this.propertyString('endpoint')
            .refuseNull()
            .refuseEmpty();

        this.propertyBool('error')
            .refuseNull();

        this.propertyObject('page')
            .allowNull()
            .setStruct(new CrappServiceResultPageValidator());

        if (dataValidator != null) {
            if (isDataArray) {
                this.propertyArray('data')
                    .refuseNull()
                    .setStruct(Type.createInstance(dataValidator, []));

            } else {
                this.propertyObject('data')
                    .refuseNull()
                    .setStruct(Type.createInstance(dataValidator, []));
            }
        }

    }
}