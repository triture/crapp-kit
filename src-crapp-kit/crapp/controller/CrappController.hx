package crapp.controller;

import crapp.model.CrappModel;
import node.express.Application;

class CrappController {

    public var route:RouteController;
    public var security:SecurityController;
    public var database:DatabaseController;
    public var log:CrappLogController;

    public function new(model:CrappModel, express:Application) {
        this.route = new RouteController(express);
        this.security = new SecurityController();
        this.database = new DatabaseController(model.database);
        this.log = new CrappLogController();
    }

    public function print(pad:Int, message:Dynamic):Void {
        var tree:String = StringTools.lpad('', '>', pad);

        Sys.println('${tree} ${Std.string(message)}');
    }

}
