package crapp.service;

import haxe.macro.Type.Ref;
import crapp.model.CrappRouteVerb;
import node.express.Response;
import node.express.Request;
import node.helper.HttpRequest;
import crapp.model.modules.logs.CrappLogData;
import crapp.model.modules.logs.CrappLogSituation;
import helper.kits.StringKit;
import crapp.model.CrappServiceResultData;
import crapp.error.CrappErrorHandler;

@:allow(crapp.controller.RouteController)
class CrappServiceBase extends CrappErrorHandler {

    private var originalVerb:CrappRouteVerb;
    private var originalRoute:String;
    private var routeTypes:Dynamic<String>;

    private var userAgent(get, null):String;
    private var userIp(get, null):String;
    private var hostname(get, null):String;

    private var req:Request;
    private var res:Response;

    private var autoLog:Bool;
    private var runtime:Int;

    private var paramsDataParsed:Bool;

    public function new() {
        this.paramsDataParsed = false;
        this.autoLog = true;
        this.runtime = this.getCurrentTimeStamp();
        super();
    }

    inline private function getCurrentTimeStamp():Int return Math.floor(haxe.Timer.stamp() * 1000);

    private function attachReqRes(req:Request, res:Response):Void {
        this.req = req;
        this.res = res;
    }

    private function get_hostname():String {
        if (this.req == null) return 'NO_REQUESTER';
        else if (this.req.hostname == null) return 'NO_HOSTNAME';
        else return this.req.hostname;
    }

    private function get_userAgent():String {
        if (this.req == null) return 'NONE';
        return StringKit.isEmpty(this.req.get('User-Agent'))
            ? 'NONE'
            : this.req.get('User-Agent');
    }

    private function get_userIp():String {
        if (this.req == null) return '0.0.0.0';
        return StringKit.isEmpty(this.req.get('x-forwarded-for'))
            ? this.req.connection.remoteAddress
            : this.req.get('x-forwarded-for');
    }

    public function getHeaderValue(header:String):String return this.req.get(header);
    public function getParamsData():Dynamic {
        var data:Dynamic = this.req.params;

        if (this.paramsDataParsed) return data;
        else {

            for (field in Reflect.fields(data)) {
                if (Reflect.hasField(this.routeTypes, field)) {
                    var valueType:String = Reflect.field(this.routeTypes, field);
                    if (valueType == 'Int') Reflect.setField(data, field, Std.parseInt(Reflect.field(data, field)));
                }
            }

            this.paramsDataParsed = true;
        }

        return data;
    }
    public function getQueryData():Dynamic return this.req.query;
    public function getBodyData():Dynamic return this.req.body;

    private function startup():Void {

    }

    private function registerLog(data:CrappServiceResultData, statusCode:Int):Void {
        var etag:String = this.res.getHeader('ETag');

        var runTime:Int = Math.floor(Math.max(0, this.getCurrentTimeStamp() - this.runtime));
        var time:String = StringTools.lpad(runTime + 'ms', ' ', 7);
        var verb:String = StringTools.lpad(this.originalVerb, ' ', 6);
        var code:String = StringTools.lpad(Std.string(statusCode), '0', 3);

        if (data.error) {
            Crapp.S.controller.print(1, 'CRAPP [ERR] ${code} ${time} ${verb} ${this.hostname} ${this.originalRoute} ' + etag);
        } else {
            Crapp.S.controller.print(1, 'CRAPP [SUC] ${code} ${time} ${verb} ${this.hostname} ${this.originalRoute} ' + etag);
        }

        var data:CrappLogData = {
            situation: data.error
                ? CrappLogSituation.ERROR
                : CrappLogSituation.SUCCESS,

            host : this.hostname,
            verb : this.originalVerb,
            route : this.originalRoute,
            status : statusCode,
            run_time : runTime,
            etag : etag,
            ip : this.userIp,
            user_agent : this.userAgent,
            message: data.error ? data.data_error.tech : null,
            debug : data.error ? this.getDebugData() : null
        }

        Crapp.S.controller.log.add(data);
    }

    private function getDebugData():Dynamic {
        var result:Dynamic = {
            headers : this.req.headers,
            body : this.getBodyData(),
            params : this.getParamsData(),
            query : this.getQueryData()
        }

        return result;
    }

}
