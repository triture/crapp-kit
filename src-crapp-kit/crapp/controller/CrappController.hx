package crapp.controller;

import node.express.Application;

class CrappController {

    public var route:RouteController;
    public var security:SecurityController;
    public var database:DatabaseController;
    public var log:CrappLogController;

    public function new(express:Application) {
        this.route = new RouteController(express);
        this.security = new SecurityController();
        this.database = new DatabaseController();
        this.log = new CrappLogController();
    }

    public function print(pad:Int, message:Dynamic):Void {
        var tree:String = StringTools.lpad('', '>', pad);

        Sys.println('${tree} ${Std.string(message)}');
    }

}
