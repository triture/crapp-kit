package crapp.service;

import haxe.Timer;
import helper.kits.TimerKit;
import crapp.model.CrappDatabaseResult;
import crapp.model.CrappDatabaseRequestData;
import crapp.controller.DatabaseController.CrappDatabase;
import node.express.Response;
import node.express.Request;

class CrappServiceDatabase<T> extends CrappService<T> {

    private var database:CrappDatabase;
    private var autoKillDatabase:Bool;
    private var lazyDatabase:Bool;

    public function new() {
        super();
        this.lazyDatabase = false;
        this.autoKillDatabase = true;
    }

    override private function startup():Void {
        if (!this.lazyDatabase) this.loadDatabaseInstance(this.run);
        else this.runServiceCallback(this.run);
    }

    private function loadDatabaseInstance(onLoad:()->Void):Void Crapp.S.controller.database.getInstance(this.onLoadDatabaseInstance.bind(onLoad));
    private function onLoadDatabaseInstance(onLoad:()->Void, conn:CrappDatabase):Void {
        this.database = conn;

        if (conn.hasError) this.resultError(CrappServiceError.SERVER_ERROR('Database connection error').getErrorModel());
        else {
            Timer.delay(
                function():Void {
                    if (this.database.isActive) Crapp.S.controller.print(1, 'DATABASE IS ALIVE FOR TOO MUCH TIME - ${this.originalVerb} ${this.req.hostname} ${this.originalRoute}');
                },
                5000
            );
            this.runServiceCallback(onLoad);
        }
    }

    public function querySelectOne<Q>(query:CrappDatabaseRequestData, onRead:(data:Q)->Void):Void this.querySelect(query, true, function(data:Array<Q>):Void onRead(data[0]));

    public function querySelect<Q>(query:CrappDatabaseRequestData, protectFrom404:Bool, onRead:(data:Array<Q>)->Void):Void {
        if (this.database == null) this.resultError(CrappServiceError.SERVER_ERROR('Database is not loaded').getErrorModel());
        else this.database.makeQuery(
            query,
            function(result:CrappDatabaseResult<Q>):Void {
                if (result.hasError) this.resultError(CrappServiceError.SERVER_ERROR(result.errorMessage).getErrorModel());
                else if (protectFrom404 && result.length == 0) this.resultError(CrappServiceError.NOT_FOUND('unable to find data > ${haxe.Json.stringify(query.data)}').getErrorModel());
                else onRead([for (item in result.result) item]);
            }
        );
    }

    override private function runBeforeSuccessExit():Void {
        super.runBeforeSuccessExit();

        if (this.database == null) return;

        this.database.commitTransaction(
            this.autoCloseDatabaseConnection,
            function():Void {
                // error
                this.database.rollbackTransaction(
                    this.autoCloseDatabaseConnection,
                    this.autoCloseDatabaseConnection
                );
            }
        );
    }

    override private function runBeforeErrorExit():Void {
        super.runBeforeErrorExit();

        if (this.database == null) return;

        this.database.rollbackTransaction(
            this.autoCloseDatabaseConnection,
            this.autoCloseDatabaseConnection
        );
    }

    private function autoCloseDatabaseConnection():Void if (this.autoKillDatabase) this.closeDatabaseConnection();
    private function closeDatabaseConnection():Void if (this.database != null) this.database.kill();


}
