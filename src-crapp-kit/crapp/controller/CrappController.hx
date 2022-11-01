package crapp.controller;

import crapp.db.DatabasePool;
import crapp.model.CrappModel;
import node.express.Application;

class CrappController {

    public var pool:DatabasePool;
    public var route:RouteController;
    public var security:SecurityController;
    public var log:CrappLogController;
    public var migration:MigrationController;

    public function new(model:CrappModel, express:Application) {
        this.route = new RouteController(express);
        this.security = new SecurityController();
        this.log = new CrappLogController();
        this.migration = new MigrationController();
        this.pool = new DatabasePool(model.database);
    }

    public function print(pad:Int, message:Dynamic):Void {
        var tree:String = StringTools.lpad('', '>', pad);

        Sys.println('${tree} ${Std.string(message)}');
    }

}
