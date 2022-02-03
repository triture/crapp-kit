package crapp.service.modules.logs;

import haxe.Timer;
import helper.chain.Chain;
import crapp.model.CrappDatabaseResult;
import crapp.model.modules.logs.CrappLogData;

class ServiceCrappLogAccessAdd extends CrappService<Bool> {

    public function new() {
        super();
        this.autoLog = false;
    }

    override public function run():Void {
        var data:CrappLogData = this.validate(this.getBodyData(), CrappLogDataValidator);
        this.resultSuccess(true);

        Crapp.S.controller.log.add(data);
    }

}
