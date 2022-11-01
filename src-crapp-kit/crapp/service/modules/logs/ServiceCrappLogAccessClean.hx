package crapp.service.modules.logs;

import crapp.db.DatabaseSuccess;

class ServiceCrappLogAccessClean extends CrappServiceDatabase<Bool> {

    override public function run():Void {
        this.query(
            {
                query : this.getDatabaseString()
            },
            this.onResult
        );
    }

    private function onResult(result:DatabaseSuccess<Dynamic>):Void {
        this.resultSuccess(true);
    }

    private function getDatabaseString():String {
        var result:String = '
            DELETE FROM crapp_log.service_log
            WHERE created_at <= DATE_ADD(NOW(), INTERVAL -90 DAY)
        ';

        return result;
    }

}
