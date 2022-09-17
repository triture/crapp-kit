package node.aws;

import js.node.buffer.Buffer;
import node.aws.model.S3UploadCBDataModel;
import node.aws.model.S3UploadParamsModel;
import node.aws.model.S3BucketParamsModel;
import node.aws.model.S3ConfigModel;

@:jsRequire("aws-sdk", "S3")
extern class S3 {

    public function new(config:S3ConfigModel);

    public function listObjects(bucketParams:S3BucketParamsModel, callback:(err:Dynamic, data:Dynamic)->Void):Void;
    public function upload(uploadParams:S3UploadParamsModel, ?callback:(err:Dynamic, data:S3UploadCBDataModel)->Void):Dynamic;
    public function getObject(params:GetObjectParams, callback:(err:Dynamic, data:GetObjectResult)->Void):Void;
    public function deleteObject(params:DeleteObjectParams, callback:(err:Dynamic, data:Dynamic)->Void):Void;
    public function deleteObjects(params:DeleteObjectsParams, callback:(err:Dynamic, data:Dynamic)->Void):Void;
}

typedef ObjectParamKey = {
    var Key:String;
}

typedef GetObjectParams = {
    > ObjectParamKey,
    var Bucket:String;
}

typedef DeleteObjectParams = {
    > GetObjectParams,
}

typedef DeleteObjectsParams = {
    var Bucket:String;
    var Delete:DeleteStrutctureParam;
}

typedef DeleteStrutctureParam = {
    var Objects:Array<ObjectParamKey>;
    var Quiet:Bool;
}

typedef GetObjectResult = {
    var Body:Buffer;
}