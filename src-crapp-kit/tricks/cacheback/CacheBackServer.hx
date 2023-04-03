package tricks.cacheback;

import haxe.ds.StringMap;
import haxe.io.BytesInput;
import haxe.io.Path;
import haxe.Timer;

class CacheBackServer {

    private var versionKey:String;
    private var timeout:Int;
    private var cachePath:String;
    private var map:StringMap<{timer:Timer, value:String}>;

    public var length(get, null):Int;

    private var autoPersistenceTimer:Timer;

    public function new(cachePath:String, ?msTimeout:Int = 50000, ?versionKey:String = 'CACHE') {
        this.cachePath = cachePath;
        this.map = new StringMap<{timer:Timer, value:String}>();
        this.timeout = msTimeout;
        this.versionKey = versionKey;

        this.load();
        this.persists();
    }

    public function clear() {
        for (item in this.map.iterator()) {
            item.timer.stop();
        }

        this.map = new StringMap<{timer:Timer, value:String}>();
    }

    public function autoPersistence(delay:Int):Void {
        if (this.autoPersistenceTimer != null) {
            this.autoPersistenceTimer.stop();
            this.autoPersistenceTimer = null;
        }

        if (delay == 0) return;

        this.autoPersistenceTimer = haxe.Timer.delay(function():Void {
            this.persists();
            this.autoPersistence(delay);
        }, delay);
    }

    public function set(key:String, value:String):Void {
        if (this.map.exists(key)) this.map.get(key).timer.stop();
        this.map.set(key, {timer:Timer.delay(this.runTimeout.bind(key), this.timeout), value:value});
    }

    public function get(key:String):String {
        if (!this.map.exists(key)) return null;

        return this.map.get(key).value;
    }

    private function runTimeout(key:String):Void {
        this.map.remove(key);
    }

    private function get_length():Int {
        var result:Int = 0;
        for (key in this.map.keys()) result++;
        return result;
    }

    public function persists():Void {
        var directory:String = Path.directory(this.cachePath);
        if (!sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);

        var content:Array<String> = [];
        content.push(this.versionKey);
        for (key in this.map.keys()) content.push(haxe.Json.stringify([key, this.map.get(key).value]));

        sys.io.File.saveContent(this.cachePath, content.join('\n'));
    }

    public function load():Void {
        if (!sys.FileSystem.exists(this.cachePath)) return;

        var bytes:BytesInput = new BytesInput(sys.io.File.getBytes(this.cachePath));

        var persistenceVersion:String = bytes.readLine();
        if (persistenceVersion != this.versionKey) return;

        while (true) {
            try {
                var data:Array<String> = haxe.Json.parse(bytes.readLine());
                this.set(data[0], data[1]);
            } catch (e:Dynamic) {
                break;
            }
        }
    }
}
