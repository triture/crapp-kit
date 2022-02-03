package crapp.service;

import haxe.Timer;
import crapp.model.CrappServiceResultPage;
import node.helper.ServiceRequester;
import anonstruct.AnonStruct;
import anonstruct.AnonStructError;
import node.express.Response;
import node.express.Request;
import crapp.model.CrappServiceErrorData;
import crapp.model.CrappServiceResultData;

@:allow(crapp.controller.RouteController)
class CrappService<T> extends CrappServiceBase {

    private var description:String;
    private var alreadyResponsed:Bool;
    private var pageSpecification:CrappServiceResultPage;

    private var timeoutTimer:Timer;

    public function new() {
        super();
        this.alreadyResponsed = false;
        this.description = "Set a service description.";
        this.setServiceTimeout();
    }

    override private function startup():Void {
        this.runServiceCallback(this.run);
    }

    public function setServiceTimeout(timeout:Int = 20000):Void {
        if (this.timeoutTimer != null) {
            this.timeoutTimer.stop();
            this.timeoutTimer.run = null;
            this.timeoutTimer = null;
        }

        if (timeout != null && timeout > 0) {
            this.timeoutTimer = Timer.delay(
                function():Void {
                    if (!this.alreadyResponsed) {
                        this.resultError(CrappServiceError.SERVER_UNAVAILABLE('Timeout Error').getErrorModel());
                    }
                },
                timeout
            );
        }
    }

    public function loadInternalService<S>(service:String, postData:Dynamic, callback:(data:S)->Void, ?headers:Array<{head:String, value:String}>):Void {
        ServiceRequester.request(
            service,
            postData,
            function(result:ServiceRequesterResult<S>):Void {
                if (!result.success) {
                    if (result.error.error_code == 500) this.resultError(CrappServiceError.SERVER_ERROR(result.error.tech).getErrorModel());
                    else if (result.error.error_code == 404) this.resultError(CrappServiceError.NOT_FOUND(result.error.tech).getErrorModel());
                    else this.resultError(CrappServiceError.INVALID_REQUEST(result.error.tech).getErrorModel());
                } else callback(result.data);
            },
            null,
            headers
        );
    }

    public function runServiceCallback(cb:Void->Void):Void this.runCallbackWithCatch(cb, this.resultError);

    private function runBeforeExit():Void {}
    private function runBeforeSuccessExit():Void {}
    private function runBeforeErrorExit():Void {}

    private function resultSuccessPaginable(?data:T, ?page:CrappServiceResultPage):Void {
        this.pageSpecification = page;
        this.resultSuccess(data);
    }

    private function resultSuccess(?data:T):Void {
        var result:CrappServiceResultData = {
            host : this.req.hostname,
            endpoint : this.req.path,
            data : data,
            error : false
        }

        if (this.pageSpecification != null) {
            result.page = this.pageSpecification;
        }

        try {

            this.runBeforeSuccessExit();
            this.runBeforeExit();

            this.doFinalResponse(200, result);
            if (this.autoLog) this.registerLog(result, 200);

        } catch (e:Dynamic) {
            var e:CrappServiceError = CrappServiceError.SERVER_ERROR(Std.string(e));
            this.resultError(e.getErrorModel());
        }
    }

    private function resultError(error:CrappServiceErrorData):Void {
        var tech:String = error.tech;

        var data:CrappServiceResultData = {
            host : this.req.hostname,
            endpoint : this.req.path,
            data : null,
            error : true,
            data_error : error
        }

        this.runBeforeErrorExit();
        this.runBeforeExit();

        #if production
        data.data_error.tech = null;
        #end
        this.doFinalResponse(error.error_code == 0 ? 404 : error.error_code, data);

        if (this.autoLog) {
            data.data_error.tech = tech;
            this.registerLog(data, data.data_error.error_code);
        }

    }

    private function doFinalResponse(statusCode:Int, data:Dynamic):Void {
        if (!this.alreadyResponsed) {
            this.alreadyResponsed = true;
            this.res.status(statusCode).json(data);
        } else {
            trace('DOUBLE RESPONSE ERROR');
            // TODO: LOGAR ESSE TIPO DE ERRO EM ALGUM LUGAR SEGURO PARA ANALIAE FUTURA
        }
    }

    private function validate(data:Dynamic, anonStruct:Class<AnonStruct>):Dynamic {
        var validator:AnonStruct = Type.createInstance(anonStruct, []);
        return this.validateUsingInstance(data, validator);
    }

    private function validateUsingInstance(data:Dynamic, validator:AnonStruct):Dynamic {
        try {
            validator.validate(data);
        } catch (e:AnonStructError) {
            throw CrappServiceError.INVALID_REQUEST(e.toString());
        } catch (e:Dynamic) {
            throw CrappServiceError.SERVER_ERROR(Std.string(e));
        }

        return data;
    }

    public function run():Void throw 'Override run() method';

    public function isProduction():Bool {
        var result:Bool = false;

        #if production
        result = true;
        #end

        return result;
    }

}
