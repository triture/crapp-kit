package crapp.model;

typedef CrappModel = {
    var public_key:String;
    var private_key:String;
    var token:String;
    var rounds:Int;
    var server_port:Int;

    var database:CrappModelDatabase;
}

typedef CrappModelDatabase = {
    var host:String;
    var user:String;
    var password:String;
    var port:Int;
}