package crapp.error;

import crapp.model.CrappServiceErrorData;
import crapp.service.CrappServiceError;

class CrappErrorHandler {

    public function new() {

    }

    private function runCallbackWithCatch(callback:Void->Void, onError:(error:CrappServiceErrorData)->Void):Void {
        try {
            callback();
        } catch (e:CrappServiceError) {
            onError(e.getErrorModel());
        } catch (e:Dynamic) {
            var ce:CrappServiceError = CrappServiceError.SERVER_ERROR(Std.string(e));
            onError(ce.getErrorModel());
        }
    }

}
