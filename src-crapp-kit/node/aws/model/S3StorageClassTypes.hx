package node.aws.model;

@:enum
abstract S3StorageClassTypes(String) from String to String {
    var STANDARD = "STANDARD";
    var REDUCED_REDUNDANCY = "REDUCED_REDUNDANCY";
    var STANDARD_IA = "STANDARD_IA";
    var ONEZONE_IA = "ONEZONE_IA";
    var INTELLIGENT_TIERING = "INTELLIGENT_TIERING";
    var GLACIER = "GLACIER";
    var DEEP_ARCHIVE = "DEEP_ARCHIVE";
}
