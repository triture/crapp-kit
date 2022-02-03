package node.aws.model;

typedef S3UploadCBDataModel = {
    var Location:String; // the URL of the uploaded object
    var ETag:String; // the ETag of the uploaded object
    var Bucket:String; // the bucket to which the object was uploaded
    var Key:String; // the key to which the object was uploaded
}
