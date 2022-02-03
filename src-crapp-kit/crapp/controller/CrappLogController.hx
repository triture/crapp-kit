package crapp.controller;

import helper.kits.FileKit;
import haxe.io.Bytes;
import helper.kits.DateKit;
import abstracts.AbstractDateTimeFormat;
import haxe.Timer;
import crapp.controller.DatabaseController.CrappDatabase;
import crapp.model.CrappDatabaseRequestData;
import crapp.model.CrappDatabaseResult;
import helper.chain.Chain;
import crapp.model.modules.logs.CrappLogData;

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
        var database:CrappDatabase = null;

        this.queue = [];


        var chain:Chain = new Chain();

        chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
            Crapp.S.controller.database.getInstance(
                function(conn:CrappDatabase):Void {
                    if (conn.hasError) abort(' --- CRAPP LOG ERROR - CANNOT GET DATABASE CONNECTION');
                    else {
                        database = conn;
                        resolve();
                    }
                }
            );
        });

        chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
            database.startTransaction(resolve, abort.bind(' --- CRAPP LOG ERROR - START TRANSACTION ERROR'));
        });

        for (item in tempQueue) {
            chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
                database.makeQuery(
                    this.getDatabaseString(item),
                    function(result:CrappDatabaseResult<Dynamic>):Void {
                        if (result.hasError) abort(' --- CRAPP LOG ERROR - ' + result.errorMessage);
                        else resolve();
                    }
                );
            });
        }

        chain.add(function(resolve:ChainResolve, abort:ChainError):Void {
            database.commitTransaction(resolve, abort.bind(' --- CRAPP LOG ERROR - COMMIT TRANSACTION ERROR'));
        });

        chain.runSerie(
            function():Void {
                if (database != null) database.kill();
                Sys.println(' --- CRAPP LOG - PERSISTENCE FOR ${tempQueue.length} ITEMS AT ${DateKit.getDateTimeMysqlFormat(Date.now(), true)}');
                this.saveDiskCache(this.queue);
            },
            function(error:String):Void {
                Sys.println(error);

                if (database != null)
                    database.rollbackTransaction(
                        function():Void {
                            Sys.println(' --- CRAPP LOG - ROLLBACK OK');
                            for (item in this.queue) tempQueue.push(item);
                            this.queue = tempQueue;
                            database.kill();
                        },
                        function():Void {
                            Sys.println(' --- CRAPP LOG - ROLLBACK ERROR --- ');
                            database.kill();
                        }
                    );
            }
        );
    }

    private function getDatabaseString(log:CrappLogData):CrappDatabaseRequestData {

        var data:Dynamic = {
            situation : log.situation,
            host : log.host,
            verb : log.verb,
            route : log.route,
            status : log.status,
            run_time : log.run_time,
            etag : log.etag,
            ip : log.ip,
            user_agent : log.user_agent,
            message : log.message,
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