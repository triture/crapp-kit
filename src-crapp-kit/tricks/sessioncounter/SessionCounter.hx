package tricks.sessioncounter;

import haxe.ds.StringMap;

class SessionCounter {

    private var threshold:Int;
    private var decreaseTime:Int;
    private var map:StringMap<Int>;

    public function new(decreaseTime:Int = 50, threshold:Int = 4) {
        this.decreaseTime = decreaseTime;
        this.threshold = 4;

        this.map = new StringMap<Int>();

        this.decrease();
    }

    private function decrease():Void {
        for (key in this.map.keys()) {
            if (this.map.get(key) <= 1) this.map.remove(key);
            else this.map.set(key, this.map.get(key) - 1);
        }

        haxe.Timer.delay(this.decrease, this.decreaseTime);
    }

    public function add(key:String):Bool {
        if (this.map.exists(key)) this.map.set(key, this.map.get(key) + 1);
        else this.map.set(key, 1);

        return (this.map.get(key) > this.threshold);
    }

    public function count(key:String):Int {
        if (this.map.exists(key)) return this.map.get(key);
        else return 0;
    }
}
