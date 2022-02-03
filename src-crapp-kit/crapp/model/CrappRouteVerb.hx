package crapp.model;

@:enum
abstract CrappRouteVerb(String) from String to String {
    var GET = "GET";
    var POST = "POST";
}
