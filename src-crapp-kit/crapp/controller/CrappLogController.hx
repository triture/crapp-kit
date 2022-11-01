package crapp.controller;

import haxe.io.Bytes;
import haxe.Timer;
import crapp.db.DatabaseError;
import crapp.db.DatabaseSuccess;
import crapp.model.CrappDatabaseRequestData;
import crapp.model.CrappDatabaseResult;
import crapp.model.modules.logs.CrappLogData;
import helper.kits.FileKit;
import helper.kits.DateKit;
import helper.chain.Chain;

class CrappLogController {

    private var queueMax:Int;
    private var queue:Array<CrappLogData>;

    private var persistsTimer:Timer;

    public function new() {
        this.queue = this.loadDiskCache();
        this.queueMax = 40;
    }

    public function add(data:CrappLogData):Void {
        data.created_at = Date.now();

        this.queue.push(data);
        this.refreshPersistsTimer();

        if (this.queue.length >= this.queueMax) this.tryToPersists();
        else this.saveDiskCache(this.queue);
    }

    private function saveDiskCache(queue:Array<CrappLogData>):Void {
        var content:Bytes = Bytes.ofString(haxe.Json.stringify(queue));
        FileKit.secureSaveData(content, '/crapp_temp/${Crapp.S.model.private_key}/log/', 'service_log.log');
    }

    private function loadDiskCache():Array<CrappLogData> {
        var data:Bytes = FileKit.secureLoadData('/crapp_temp/${Crapp.S.model.private_key}/log/', 'service_log.log');
        if (data == null) return [];
        else return haxe.Json.parse(data.toString());
    }

    private function refreshPersistsTimer():Void {
        if (this.persistsTimer != null) {
            this.persistsTimer.stop();
            this.persistsTimer.run = null;
            this.persistsTimer = null;
        }

        this.persistsTimer = Timer.delay(this.tryToPersists, 30000); // 30 seconds
    }

    private function tryToPersists():Void {
        if (this.queue.length == 0) return;

        var tempQueue:Array<CrappLogData> = this.queue;
        var databaseTicket:String;

        this.queue = [];


        var chain:Chain = new Chain();

        chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
            Crapp.S.controller.pool.getTicket(function(ticket:String):Void {
                databaseTicket = ticket;
                resolve();
            }, 10000);
        });

        for (item in tempQueue) {
            chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
                Crapp.S.controller.pool.query(
                    databaseTicket,
                    this.getDatabaseString(item),
                    function(data:DatabaseSuccess<Dynamic>):Void resolve(),
                    function(err:DatabaseError):Void abort(' --- CRAPP LOG ERROR - ' + err.message)
                );
            });
        }

        chain.runSerie(
            function():Void {
                Crapp.S.controller.pool.closeTicket(
                    databaseTicket,
                    function():Void {
                        Sys.println(' --- CRAPP LOG - PERSISTENCE FOR ${tempQueue.length} ITEMS AT ${DateKit.getDateTimeMysqlFormat(Date.now(), true)}');
                        this.saveDiskCache(this.queue);
                    }
                );
            },
            function(error:String):Void {
                Sys.println(error);

                Crapp.S.controller.pool.closeTicket(
                    databaseTicket,
                    function():Void {
                        Sys.println(' --- CRAPP LOG - ROLLBACK OK');
                        for (item in this.queue) tempQueue.push(item);
                        this.queue = tempQueue;
                    },
                    true
                );

            }
        );
    }

    private function getDatabaseString(log:CrappLogData):CrappDatabaseRequestData {

        var data:Dynamic = {
            situation : log.situation,
            host : log.host == null ? 'NO' : log.host.substr(0, 1024),
            verb : log.verb,
            route : log.route,
            status : log.status,
            run_time : log.run_time,
            etag : log.etag == null ? null : log.etag.substr(0, 256),
            ip : log.ip == null ? null : log.ip.substr(0, 256),
            user_agent : log.user_agent == null ? null : log.user_agent.substr(0, 2048),
            message : log.message == null ? null : log.message.substr(0, 2048),
            created_at : log.created_at
        };

        if (log.debug == null) {
            data.has_debug = 'no';
            data.debug_value = '';
            data.crypt_key = '';
        } else {
            data.has_debug = 'yes';
            data.debug_value = haxe.Json.stringify(log.debug);
            data.crypt_key = log.etag + '//' + Sys.getEnv('CRAPP_PRIVATE_KEY');
        }

        var query:String = '
            INSERT INTO crapp_log.service_log (
                situation,
                host,
                verb,
                route,
                status,
                run_time,
                etag,
                ip,
                user_agent,
                message,
                debug,
                created_at
            )

            VALUES (
                :situation,
                :host,
                :verb,
                :route,
                :status,
                :run_time,
                :etag,
                :ip,
                :user_agent,
                :message,
                IF(:has_debug = "yes", AES_ENCRYPT(:debug_value, UNHEX(SHA2(:crypt_key, 512))), NULL),
                :created_at
            )
        ';

        return {
            query : query,
            data : data
        };
    }


}