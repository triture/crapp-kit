package crapp.service.modules.logs;

import crapp.model.CrappDatabaseResult;

class ServiceCrappLogAccessClean extends CrappServiceDatabase<Bool> {

    override public function run():Void {
        this.database.make(
            this.getDatabaseString(),
            null,
            this.onResult
        );
    }

    private function onResult(result:CrappDatabaseResult<Dynamic>):Void {
        if (result.hasError) this.resultError(CrappServiceError.SERVER_ERROR(result.errorMessage).getErrorModel());
        else this.resultSuccess(true);
    }

    private function getDatabaseString():String {
        var result:String = '
            DELETE FROM crapp_log.service_log
            WHERE created_at <= DATE_ADD(NOW(), INTERVAL -90 DAY)
        ';

        return result;
    }

}
