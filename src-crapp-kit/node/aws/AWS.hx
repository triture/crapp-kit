package node.aws;

import node.aws.model.AWSConfigModel;

@:jsRequire('aws-sdk')
extern class AWS {

    public function new();

    public static var config:AWSConfig;

}


private extern class AWSConfig {

    public function getCredentials(callback:(err:Dynamic)->Void):Void;
    public function update(config:AWSConfigModel):Void;

    public var credentials:AWSConfigCredentials;

}


private extern class AWSConfigCredentials {
    var accessKeyId:String;
    var secretAccessKey:String;
}
