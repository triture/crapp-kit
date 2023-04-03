package tricks.sharp;

import haxe.io.Bytes;
import js.node.buffer.Buffer;

class ImageSharp {

    public function new() {

    }

    public function noise(width:Int, height:Int, callback:(data:Bytes)->Void):Void {

        var sharp:Dynamic = js.Syntax.code('require({0})', 'sharp');

        sharp({
            create : {
                width : width,
                height : height,
                channels: 3,
                noise: {
                    type: 'gaussian',
                    mean: 128,
                    sigma: 30
                }
            }
        }).jpeg({
            quality: 88,
            chromaSubsampling: '4:4:4'
        }).toBuffer(
            function(err:Dynamic, data:Buffer, info:Dynamic):Void {
                callback(data.hxToBytes());
            }
        );

    }

    public function resize(bytes:Bytes, maxImageWidth:Int, maxImageHeight:Int, callback:(err:Bool, resized:Bytes)->Void):Void {

        var sharp:Dynamic = js.Syntax.code('require({0})', 'sharp');

        var buffer:Buffer = Buffer.hxFromBytes(bytes);
        var fitType:String = maxImageWidth == maxImageHeight && maxImageWidth == 2000 ? 'inside' : 'cover';

        try {
            sharp(buffer)
                .resize(
                    maxImageWidth,
                    maxImageHeight,
                    {
                        fit : fitType,
                        withoutEnlargement: true
                    }
                )
                .flatten(
                    {
                        background : { r: 255, g: 255, b: 255}
                    }
                )
                .jpeg({
                    quality: 88,
                    chromaSubsampling: '4:4:4'
                })
                .toBuffer(
                    function(err:Dynamic, data:Buffer, info:Dynamic):Void {

                        if (err != null) {
                            // trace(err);
                            callback(true, null);

                        } else {

                            callback(false, data.hxToBytes());
                        }
                    }
                );
        } catch (e:Dynamic) {
            trace(e);
            callback(true, null);
        }
    }

}
