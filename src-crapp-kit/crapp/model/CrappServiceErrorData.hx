package crapp.model;

typedef CrappServiceErrorData = {
    var error_code:Int;
    var message:String;

    @:optional var error_data:Dynamic;
    @:optional var tech:String;
}