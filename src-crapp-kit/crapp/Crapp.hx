package crapp;

import crapp.service.modules.logs.ServiceCrappLogAccessClean;
import crapp.service.modules.logs.ServiceCrappLogAccessAdd;
import crapp.model.CrappRouteVerb;
import node.express.Express;
import node.express.Application;
import crapp.controller.CrappController;
import crapp.model.CrappModel;

class Crapp {

    public static var S:Crapp;
    private var express:Application = Express.application();

    public var controller:CrappController;

    public var model:CrappModel;

    public function new(model:CrappModel) {
        if (S == null) S = this;
        else throw "Cannot Create more than one CRAPP Instance";

        this.model = model;

        this.controller = new CrappController(model, this.express);
        this.controller.migration.run(this.startServer);
    }

    public function registerServices():Void {
        Crapp.S.controller.route.registerService(CrappRouteVerb.POST, '/crapp/log/access/add', ServiceCrappLogAccessAdd);
        Crapp.S.controller.route.registerService(CrappRouteVerb.POST, '/crapp/log/access/clean', ServiceCrappLogAccessClean);
    }

    private function startServer():Void {
        var cors:Dynamic = js.Syntax.code("require({0})", 'cors');

        this.express.use(cors());
        this.express.use(Express.urlencoded({extended:true}));
        this.express.use(Express.json({limit:'10mb'}));
        this.express.use(Express.text({limit:'10mb'}));

        this.express.options('*', cors());

        Crapp.S.controller.print(0, 'CRAPP is starting Services');

        this.express.listen(
            this.model.server_port,
            function():Void {

                Crapp.S.controller.print(1, 'Crapp running in port ${this.model.server_port}');
                this.registerServices();
                Crapp.S.controller.print(1, 'All Services up\n\n');
            }
        );

    }
}
