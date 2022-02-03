package crapp.model.modules.logs;

import abstracts.AbstractDateTimeFormat;
import anonstruct.AnonStruct;

typedef CrappLogData = {
    var situation:CrappLogSituation;
    var host:String;
    var verb:CrappRouteVerb;
    var route:String;
    var status:Int;
    var run_time:Int;
    var etag:String;
    var ip:String;
    var user_agent:String;
    @:optional var message:String;
    @:optional var debug:Dynamic;
    @:optional var created_at:AbstractDateTimeFormat;
}

class CrappLogDataValidator extends AnonStruct {
    public function new() {
        super();

        this.propertyString('situation')
            .refuseNull()
            .refuseEmpty()
            .setAllowedOptions([
                CrappLogSituation.SUCCESS,
                CrappLogSituation.ERROR
            ]);

        this.propertyString('host')
            .refuseNull()
            .refuseEmpty();

        this.propertyString('verb')
            .refuseNull()
            .refuseEmpty()
            .setAllowedOptions([
                CrappRouteVerb.GET,
                CrappRouteVerb.POST
            ]);

        this.propertyString('route')
            .refuseNull()
            .refuseEmpty();

        this.propertyInt('status')
            .refuseNull()
            .addValidation(function(value:Int):Void {
                if (value == 0 || value >= 100) return;
                else throw 'Value must be greater then 100';
        });

        this.propertyInt('run_time')
            .refuseNull()
            .greaterOrEqualThan(0);

        this.propertyString('etag')
            .refuseNull()
            .refuseEmpty();

        this.propertyString('ip')
            .refuseNull()
            .refuseEmpty();

        this.propertyString('user_agent')
            .refuseNull()
            .refuseEmpty();

        this.propertyString('message')
            .allowNull()
            .refuseEmpty();

        this.propertyObject('debug')
            .allowNull();

    }
}
