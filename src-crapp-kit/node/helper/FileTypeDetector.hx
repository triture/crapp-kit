package node.helper;

import helper.kits.StringKit;
import js.Promise;
import haxe.io.Bytes;

class FileTypeDetector {

    static public function detect(filename:String, data:Bytes, callback:(data:FileTypeDetectorData)->Void):Void {

        var ft:Dynamic = js.Syntax.code('require({0})', 'file-type');
        var buf = js.node.buffer.Buffer.hxFromBytes(data);

        ft
        .fromBuffer(buf)
        .then(
            function(data:Dynamic):Void validateResult(data, filename, callback),
            function(data):Void validateResult(data, filename, callback)
        );
    }

    static private function validateResult(result:FileTypeDetectorData, filename:String, callback:(data:FileTypeDetectorData)->Void):Void {
        if (result == null) {

            var mime:Dynamic = js.Syntax.code('require({0})', 'mime-types');
            var mimeInfo:String = mime.lookup(filename) == false ? 'application/octet-stream' : mime.lookup(filename);

            result = {
                ext : getExtentionFromFilename(filename),
                mime : mimeInfo
            }

        }

        callback(result);
    }

    static private function getExtentionFromFilename(filename:String):String {
        var filePart:Array<String> = filename.split('.');
        if (filePart.length > 1) {
            var ext:String = filePart.pop();
            var file:String = filePart.join('.');

            if (!StringKit.isEmpty(file) && !StringKit.isEmpty(ext) && ext.length <= 10) {
                return ext;
            }
        }

        return '';
    }

}

typedef FileTypeDetectorData = {
    var ext:String;
    var mime:String;
}