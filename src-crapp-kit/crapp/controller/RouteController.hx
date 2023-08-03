package crapp.controller;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import node.helper.HttpRequest;
import node.express.Response;
import node.express.Request;
import node.express.Application;
import crapp.model.CrappRouteVerb;
import crapp.service.CrappService;

class RouteController {

    private var express:Application;

    public function new(express:Application) {
        this.express = express;
    }

    // TIP : Use /my/route/[id:Int]/[name:String]
    public function registerService<T>(verb:CrappRouteVerb, route:String, service:Class<CrappService<T>>):Void {
        Crapp.S.controller.print(1, 'ROUTE - ${verb} ${route} ${Type.getClassName(service)}');

        var routeCleaned:String = GET_CLEAN_ROUTE(route);
        var routeTypes:Dynamic<String> = GET_ROUTE_TYPES(route);

        switch (verb) {
            case CrappRouteVerb.GET : this.express.get(routeCleaned, this.serviceRunner.bind(verb, route, routeTypes, service, _, _));
            case CrappRouteVerb.POST : this.express.post(routeCleaned, this.serviceRunner.bind(verb, route, routeTypes, service, _, _));
        }

    }

    static public function GET_CLEAN_ROUTE(route:String):String {
        var r:EReg = ~/\[(\w+):(Int|String)\]/;
        var result:String = route;

        while (r.match(route)) {
            result = result.split(r.matched(0)).join(':' + r.matched(1));
            route = r.matchedRight();
        }

        return result;
    }

    static public function GET_ROUTE_TYPES(route:String):Dynamic<String> {
        var result:Dynamic = {};
        var r:EReg = ~/\[(\w+):(Int|String)\]/;

        while (r.match(route)) {
            Reflect.setField(result, r.matched(1), r.matched(2));
            route = r.matchedRight();
        }

        return result;
    }

    private function serviceRunner<T>(verb:CrappRouteVerb, route:String, routeTypes:Dynamic<String>, service:Class<CrappService<T>>, req:Request, res:Response):Void {
        var serviceInstance:CrappService<T> = Type.createInstance(service, []);
        serviceInstance.originalVerb = verb;
        serviceInstance.originalRoute = route;
        serviceInstance.routeTypes = routeTypes;

        serviceInstance.attachReqRes(req, res);
        serviceInstance.startup();

    }

    public function registerJson(verb:CrappRouteVerb, route:String, path:String):Void {
        Crapp.S.controller.print(1, 'ROUTE - [JSON] ${verb} ${route} ${path}');

        switch (verb) {
            case CrappRouteVerb.GET : this.express.get(route, this.jsonRunner.bind(path, _, _));
            case CrappRouteVerb.POST : this.express.post(route, this.jsonRunner.bind(path, _, _));
        }
    }

    private function jsonRunner(path:String, req:Request, res:Response):Void {
        try {
            if (!FileSystem.exists(path)) throw 'Invalid Path';
            
            var data:String = File.getContent(path);
            var json:Dynamic = Json.parse(data);

            res.status(200).json(json);

        } catch (e:Dynamic) {
            res.status(500).json({error : Std.string(e)});
        }
    }

    public function registerProxy(verb:CrappRouteVerb, route:String, proxyURL:String):Void {
        Crapp.S.controller.print(1, 'PROXY - ${verb} ${route} ${proxyURL}');

        switch (verb) {
            case CrappRouteVerb.GET : this.express.get(route, this.proxyRunner.bind(proxyURL, _, _));
            case CrappRouteVerb.POST : this.express.post(route, this.proxyRunner.bind(proxyURL, _, _));
        }
    }

    private function proxyRunner(proxyURL:String, req:Request, res:Response):Void {
        var http:HttpRequest = new HttpRequest(proxyURL);
    }

}
