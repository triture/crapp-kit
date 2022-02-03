package node.helper.storage;

import js.node.buffer.Buffer;
import service.media.model.StorageAWSCloudData;
import helper.kits.StringKit;
import node.aws.model.S3StorageClassTypes;
import node.aws.model.S3ACLTypes;
import node.aws.model.S3UploadParamsModel;
import node.aws.model.S3UploadCBDataModel;
import haxe.io.Bytes;
import node.aws.model.S3ConfigModel;
import node.aws.S3;

class AmazonStorage {

    private var s3:S3;
    private var bucket:String;

    public function new(region:String, bucket:String, accessKeyId:String, secretAccessKey:String) {

        this.bucket = bucket;

        var s3Config:S3ConfigModel = {
            apiVersion: '2006-03-01',
            region: region,

            httpOptions : {
                connectTimeout : 1500
            },

            accessKeyId : accessKeyId,
            secretAccessKey : secretAccessKey
        }

        this.s3 = new S3(s3Config);
    }

    public function download(data:StorageAWSCloudData, callback:(error:Null<String>, data:Bytes)->Void):Void {
        this.s3.getObject(
            {
                Bucket : data.bucket,
                Key : data.key
            },
            function(err:Dynamic, data:GetObjectResult):Void {
                if (err != null) callback(Std.string(err), null);
                else callback(null, data.Body.hxToBytes());
            }
        );
    }

    public function upload(data:Bytes, path:String, contentType:String, onResult:(error:Null<String>, data:Null<S3UploadCBDataModel>)->Void):Void {

        var filename:String = path + '/' + StringKit.generateRandomHex(64);
        var dataBuffer = js.node.buffer.Buffer.hxFromBytes(data);

        var uploadParams:S3UploadParamsModel = {
            Key : filename,
            Bucket : this.bucket,
            Body : dataBuffer,
            ACL : S3ACLTypes.PRIVATE,
            StorageClass : S3StorageClassTypes.STANDARD,
            ContentType : contentType
        }

        this.s3.upload(uploadParams, this.onUpload.bind(onResult));
    }

    private function onUpload(onResult:(error:Null<String>, data:Null<S3UploadCBDataModel>)->Void, err:Dynamic, data:S3UploadCBDataModel):Void {
        if (err != null) {

            onResult(Std.string(err), null);
        } else {
            onResult(null, data);
        }

    }

}