package crapp.model;

import crapp.service.CrappService;

typedef ModuleRouteData = {

    var verb:CrappRouteVerb;
    var route:String;
    var service:Class<CrappService>;

}
