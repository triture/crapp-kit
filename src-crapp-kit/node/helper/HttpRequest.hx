package node.helper;

import js.node.Buffer;
import haxe.io.Bytes;
import js.node.http.IncomingMessage;
import helper.kits.StringKit;
import js.node.url.URL;
import haxe.ds.StringMap;

class HttpRequest {

    private var headers:StringMap<{head:String, value:String}>;
    private var params:Array<{name:String, value:String}>;
    private var method:String;
    private var body:String;
    private var url:String;
    private var timeout:Int;
    private var binaryRequest:Bool;

    public var autoRedirect:Bool = true;

    private var onResult:(result:HttpRequestResult)->Void;

    public function new(?url:String) {
        this.headers = new StringMap<{head:String, value:String}>();
        this.params = [];
        this.method = 'GET';
        this.body = '';
        this.url = url;
        this.timeout = 10000;
        this.binaryRequest = false;
    }

    public function setBinaryRequest():HttpRequest {
        this.binaryRequest = true;
        return this;
    }

    public function setTimeout(msec:Int):HttpRequest {
        this.timeout = msec;
        return this;
    }

    public function setMethod(method:String):HttpRequest {
        this.method = method.toUpperCase();
        return this;
    }

    public function setCallback(cb:(result:HttpRequestResult)->Void):HttpRequest {
        this.onResult = cb;
        return this;
    }

    public function doPost():HttpRequest return this.setMethod('POST');
    public function doGet():HttpRequest return this.setMethod('GET');

    public function addFormData(name:String, value:String):HttpRequest {
        if (StringKit.isEmpty(name) || value == null) return this;
        else {
            this.body += (StringKit.isEmpty(this.body) ? '' : '&') + StringTools.urlEncode(name) + '=' + StringTools.urlEncode(value);
            this.addHeader('Content-Type', 'application/x-www-form-urlencoded');
            this.addHeader('Content-Length', Std.string(Bytes.ofString(this.body).length));
        }

        return this;
    }

    public function addParam(name:String, value:String):HttpRequest {
        if (StringKit.isEmpty(name) || value == null) return this;
        else this.params.push({name:name, value:value});

        return this;
    }

    public function setBody(body:String):HttpRequest {
        this.body = body;
        this.addHeader('Content-Length', Std.string(Bytes.ofString(this.body).length));
        return this;
    }

    public function addHeader(head:String, value:String):HttpRequest {
        if (head == null) return this;
        else if (value == null) this.headers.remove(head.toLowerCase());
        else this.headers.set(head.toLowerCase(), {head:head, value:value});

        return this;
    }

    public function setJsonBody(data:Dynamic):HttpRequest return this.addHeader('Content-Type', 'application/json; charset=utf-8').setBody(haxe.Json.stringify(data));
    public function doJsonPost(data:Dynamic):HttpRequest return this.doPost().setJsonBody(data);

    public function execute(?url:String):Void {
        if (!StringKit.isEmpty(url)) this.url = url;
        else if (StringKit.isEmpty(this.url)) throw 'Request address is undefided';

        var u:URL = new URL(this.url);

        var protocol:String = u.protocol;
        var secure:Bool = protocol == 'https:';
        var host:String = u.hostname;
        var port:Int = if (u.port != null) Std.parseInt(u.port) else (secure ? 443 : 80);
        var path = u.pathname;

        // setting params
        var params:Array<{name:String, value:String}> = [];
        u.searchParams.forEach(
            function(v:String, n:String):Void {
                params.push({name:n, value:v});
            }
        );
        for (item in this.params) params.push(item);
        if (params.length > 0) {
            path += '?';
            for (item in params)
                path += StringTools.urlEncode(item.name)
                + "="
                + StringTools.urlEncode(item.value) + '&';
        }

        var opts:Dynamic = {
            protocol : protocol,
            hostname : host,
            port : port,
            method : this.method,
            path : path,
            headers : {},
            timeout : this.timeout
        };

        for (h in this.headers) Reflect.setField(opts.headers, h.head, h.value);

        function httpResponse(res:IncomingMessage) {
            var result:HttpRequestResult = new HttpRequestResult();
            result.status = res.statusCode;
            result.body = "";

            var binChunck:Array<Dynamic> = [];

            for (key in res.headers.keys()) result.headers.set(
                key.toLowerCase(),
                {head : key, value : res.headers.get(key)}
            );

            if (this.binaryRequest) res.on('data', function(data:String):Void binChunck.push(data));
            else res.on('data', function(data:String):Void result.body += data);

            res.on('end', function(_) {

                result.isSuccess = (
                    res.complete &&
                    result.status != null &&
                    result.status >= 200 &&
                    result.status < 400
                );

                if (result.status == 302 && this.autoRedirect && result.headers.exists('location')) {
                    new HttpRequest(result.headers.get('location').value)
                    .doGet()
                    .setCallback(this.onResult)
                    .execute();
                } else {
                    if (this.binaryRequest) result.binData = Buffer.concat(binChunck);
                    if (this.onResult != null) this.onResult(result);
                }
            });
        }

        function onError() {
            var result:HttpRequestResult = new HttpRequestResult();
            result.isSuccess = false;
            result.status = 0;
            result.binData = Buffer.concat([]);
            result.body = '';
            if (this.onResult != null) this.onResult(result);
        };

        if (secure) {
            var r = js.node.Https.request(untyped opts, httpResponse);
            r.on('error', onError);
            if (this.body.length > 0) r.write(this.body);
            r.end();
        } else {
            var r = js.node.Http.request(untyped opts, httpResponse);
            r.on('error', onError);
            if (this.body.length > 0) r.write(this.body);
            r.end();
        }

    }

}

class HttpRequestResult {

    public var status:Null<Int>;
    public var body:String;
    public var headers:StringMap<{head:String, value:String}>;
    public var json(get, null):Dynamic;
    public var base64(get, null):String;

    public var binData:Buffer;
    public var isSuccess:Bool;

    private var parsedJson:Dynamic;

    public function new() {
        this.headers = new StringMap<{head:String, value:String}>();
    }

    private function get_base64():String {
        if (this.binData == null) return null;
        else return this.binData.toString('base64');
    }

    public function getHeader(head:String):String
        return head == null || !this.headers.exists(head.toLowerCase())
            ? ''
            : this.headers.get(head.toLowerCase()).value;

    private function get_json():Dynamic {
        if (this.parsedJson != null) return this.parsedJson;
        else {
            if (StringKit.isEmpty(this.body) || this.getHeader('content-type').indexOf('application/json') != 0) return null;
            else {
                try {
                    this.parsedJson = haxe.Json.parse(this.body);
                } catch (e:Dynamic) {

                }

                return this.parsedJson;
            }
        }
    }
}