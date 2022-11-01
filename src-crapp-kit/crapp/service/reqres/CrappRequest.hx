package crapp.service.reqres;

import haxe.ds.StringMap;

class CrappRequest {

    public var verb:String;
    public var route:String;
    public var routeParams:StringMap<CrappParameterType>;

    public var header:StringMap<String>;

    public var userIp:String;
    public var hostname:String;
    public var isBodyJson:Bool;

    public var dataQuery:Dynamic;
    public var dataBody:Dynamic;
    public var dataRouteParams:Dynamic;

}
