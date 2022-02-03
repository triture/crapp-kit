package node.aws.model;

typedef S3UploadParamsModel = {
    var Bucket:String;
    var Body:Dynamic; // (Buffer, Typed Array, Blob, String, ReadableStream
    var Key:String;

    @:optional var ContentType:String;
    @:optional var ContentEncoding:String;
    @:optional var ACL:S3ACLTypes;
    @:optional var StorageClass:S3StorageClassTypes;
}
