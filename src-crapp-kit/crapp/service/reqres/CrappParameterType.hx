package crapp.service.reqres;

import haxe.ds.StringMap;

@:enum
abstract CrappParameterType(String) from String to String {
    var STRING = "String";
    var INT = "Int";

    static public function GET_CLEAN_ROUTE(route:String, ?converter:(param:String, type:String)->String):String {
        var result:String = route;
        var r:EReg = ~/\[(\w+):(Int|String)\]/;

        var defaultConverter:(param:String, type:String)->String = function(param:String, type:String):String {
            return ':${param}';
        }

        if (converter != null) defaultConverter = converter;

        while (r.match(route)) {
            result = result.split(r.matched(0)).join(defaultConverter(r.matched(1), r.matched(2)));
            route = r.matchedRight();
        }

        return result;
    }

    static public function GET_ROUTE_PARAMETERS(route:String):StringMap<CrappParameterType> {
        var result:StringMap<CrappParameterType> = new StringMap<CrappParameterType>();
        var r:EReg = ~/\[(\w+):(Int|String)\]/;

        while (r.match(route)) {
            result.set(r.matched(1), r.matched(2));
            route = r.matchedRight();
        }

        return result;
    }
}
