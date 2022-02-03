package node.aws.model;

@:enum
abstract S3ACLTypes(String) to String from String {
    var PRIVATE = "private";
    var PUBLIC_READ = "public-read";
    var PUBLIC_READ_WRITE = "public-read-write";
    var AUTHENTICATED_READ = "authenticated-read";
    var AWS_EXEC_READ = "aws-exec-read";
    var BUCKET_OWNER_READ = "bucket-owner-read";
    var BUCKET_OWNER_FULL_CONTROL = "bucket-owner-full-control";
}
