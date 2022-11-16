package crapp.service;

import crapp.db.DatabaseSuccess;
import crapp.db.DatabaseError;
import crapp.model.CrappDatabaseRequestData;

class CrappServiceDatabase<T> extends CrappService<T> {

    private var useTransaction:Bool;
    private var ticket:String;

    public function new(useTransaction:Bool = true) {
        this.useTransaction = useTransaction;
        super();
    }

    override private function startup():Void {
        this.loadDatabaseTicket(this.run);
    }

    private function loadDatabaseTicket(onLoad:()->Void):Void {
        Crapp.S.controller.pool.getTicket(function(ticket:String):Void {

            this.ticket = ticket;
            this.runServiceCallback(onLoad);

        }, 15000, this.useTransaction);
    }

    public function query<Q>(query:CrappDatabaseRequestData, onComplete:(success:DatabaseSuccess<Q>)->Void, ?onError:(err:DatabaseError)->Void):Void {
        Crapp.S.controller.pool.query(
            this.ticket,
            query,
            onComplete,
            function(err:DatabaseError):Void {
                if (onError == null) this.resultError(CrappServiceError.SERVER_ERROR(err.message).getErrorModel());
                else onError(err);
            }
        );
    }

    public function queryRun(query:CrappDatabaseRequestData, onComplete:()->Void):Void {
        this.query(
            query,
            function(success:DatabaseSuccess<Dynamic>):Void {
                onComplete();
            }
        );
    }

    public function querySelectOne<Q>(query:CrappDatabaseRequestData, onRead:(data:Q)->Void):Void this.querySelect(query, true, function(data:Array<Q>):Void onRead(data[0]));

    public function querySelect<Q>(query:CrappDatabaseRequestData, protectFrom404:Bool, onRead:(data:Array<Q>)->Void):Void {
        this.query(
            query,
            function(success:DatabaseSuccess<Q>):Void {
                if (protectFrom404 && success.length == 0) {
                    this.resultError(CrappServiceError.NOT_FOUND('unable to find data > ${haxe.Json.stringify(query.data)}').getErrorModel());
                } else {
                    var result:Array<Q> = [];
                    for (item in success.raw) result.push(item);

                    onRead(result);
                }
            }
        );
    }

    override private function runBeforeSuccessExit():Void {
        super.runBeforeSuccessExit();

        if (this.ticket != null) {
            Crapp.S.controller.pool.closeTicket(
                this.ticket,
                function():Void {}
            );
        }
    }

    override private function runBeforeErrorExit():Void {
        super.runBeforeErrorExit();

        if (this.ticket != null) {
            Crapp.S.controller.pool.closeTicket(
                this.ticket,
                function():Void {},
                true
            );
        }
    }

}
