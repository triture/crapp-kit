package node.helper;

import crapp.model.CrappServiceErrorData;
import crapp.model.CrappServiceResultData;
import helper.kits.StringKit;
import node.helper.HttpRequest.HttpRequestResult;

class ServiceRequester {

    static public var DEFAULT_URL:String = 'http://127.0.0.1';

    static public function request<S, R>(service:String, postData:S, callback:(result:ServiceRequesterResult<R>)->Void, ?bearerToken:String, ?headers:Array<{head:String, value:String}>):Void {
        var fullUrl:String = (StringTools.startsWith(service, 'http') ? service : DEFAULT_URL + service);
        var http:HttpRequest = new HttpRequest(fullUrl);

        if (postData != null) http.doJsonPost(postData);
        if (!StringKit.isEmpty(bearerToken)) http.addHeader('Authorization', bearerToken);

        if (headers != null) for (head in headers) http.addHeader(head.head, head.value);

        http.setCallback(
            function(data:HttpRequestResult):Void {
                var validator:CrappServiceResultDataValidator = new CrappServiceResultDataValidator();
//
                if (validator.pass(data.json)) {
                    var result:CrappServiceResultData = cast data.json;

                    if (result.error) callback(
                        {
                            success : false,
                            data : null,
                            error : result.data_error
                        }
                    )
                    else callback(
                        {
                            success : true,
                            data : result.data,
                            error : null
                        }
                    );

                } else {
                    callback(
                        {
                            success : false,
                            data : null,
                            error : {
                                error_code : 0,
                                message : 'Invalid result from server',
                                error_data : data.json,
                                tech : 'Invalid format'
                            }
                        }
                    );
                }

            }
        ).execute();
    }

}

typedef ServiceRequesterResult<T> = {
    var success:Bool;
    var data:T;
    var error:CrappServiceErrorData;
}