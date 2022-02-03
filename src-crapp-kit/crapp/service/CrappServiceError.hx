package crapp.service;

import helper.kits.StringKit;
import crapp.model.CrappServiceErrorData;
import haxe.Exception;

class CrappServiceError extends Exception {

    public var errorCode:Int;
    public var errorMessage:String;
    public var errorTechMessage:String;
    public var errorData:Dynamic;

    private function new(message:String, ?previous:Exception, ?native:Any):Void {
        super(message, previous, native);
    }

    static public function ERROR(code:Int, message:String, ?techMessage:String, ?data:Dynamic):CrappServiceError {
        var e:CrappServiceError = new CrappServiceError(message);
        e.errorCode = code;
        e.errorMessage = message;
        e.errorTechMessage = techMessage;
        e.errorData = data;

        return e;
    }

    // Essa resposta significa que o servidor não entendeu a requisição pois está com uma sintaxe inválida.
    static public function INVALID_REQUEST(techMessage:String):CrappServiceError return ERROR(400, "Bad Request", techMessage);
    static public function INVALID_REQUEST_DETAILED(message:String, techMessage:String):CrappServiceError return ERROR(400, message, techMessage);

    // Embora o padrão HTTP especifique "unauthorized", semanticamente, essa resposta significa "unauthenticated".
    // Ou seja, o cliente deve se autenticar para obter a resposta solicitada.
    // https://developer.mozilla.org/pt-BR/docs/Web/HTTP/Status/401
    static public function UNAUTHORIZED_REQUEST(techMessage:String):CrappServiceError return ERROR(401, "Unauthorized", techMessage);

    // O cliente não tem direitos de acesso ao conteúdo portanto o servidor está rejeitando dar a resposta.
    // Diferente do código 401, aqui a identidade do cliente é conhecida.
    // Esse status é semelhante ao 401 , mas neste caso, a re-autenticação não fará diferença.
    // O acesso é permanentemente proibido e vinculado à lógica da aplicação (como uma senha incorreta).
    // https://developer.mozilla.org/pt-BR/docs/Web/HTTP/Status/403
    static public function FORBIDDEN(message:String, ?techMessage:String):CrappServiceError return ERROR(403, message, techMessage);

    // O servidor não pode encontrar o recurso solicitado.
    static public function NOT_FOUND(techMessage:String):CrappServiceError return ERROR(404, 'Not Found', techMessage);

    // Esta resposta será enviada quando uma requisição conflitar com o estado atual do servidor.
    static public function CONFLICT(message:String, techMessage:String):CrappServiceError return ERROR(409, message, techMessage);

    // O servidor encontrou uma situação com a qual não sabe lidar.
    static public function SERVER_ERROR(techMessage:String):CrappServiceError return ERROR(500, "Server Error", techMessage);

    static public function SERVER_UNAVAILABLE(techMessage:String):CrappServiceError return ERROR(503, "Service Unavailable", techMessage);

    public function getErrorModel():CrappServiceErrorData {
        var result:CrappServiceErrorData = {
            error_code : this.errorCode,
            message : this.errorMessage
        }

        if (!StringKit.isEmpty(this.errorTechMessage)) result.tech = this.errorTechMessage;
        if (this.errorData != null) result.error_data = this.errorData;

        return result;
    }
}