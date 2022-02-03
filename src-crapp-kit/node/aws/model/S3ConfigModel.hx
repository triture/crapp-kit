package node.aws.model;

typedef S3ConfigModel = {
    var apiVersion:String;

    @:optional var region:String;
    @:optional var httpOptions:Dynamic;

    @:optional var accessKeyId:String;
    @:optional var secretAccessKey:String;

    @:optional var maxRetries:Int;
}
