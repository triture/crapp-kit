package tricks.multimap;

import haxe.ds.ObjectMap;

class ArrayMap<K:{}, V:{}> {

    private var map:ObjectMap<K, Array<V>>;

    public function new() {
        this.map = new ObjectMap<K, Array<V>>();
    }

    public function keys():Array<K> return [for (key in this.map.keys()) key];

    public function exists(key:K):Bool return this.map.exists(key);

    public function add(key:K, value:V):Void {
        var data:Array<V> = this.getValues(key);
        if (data.indexOf(value) == -1) data.push(value);

        this.map.set(key, data);
    }

    public function getValues(key:K):Array<V> {
        if (!this.map.exists(key)) return [];
        else return this.map.get(key);
    }

    public function removeValue(key:K, value:V):Void {
        var data:Array<V> = this.getValues(key);
        if (data.indexOf(value) > -1) data.remove(value);
        if (data.length == 0) this.map.remove(key);
    }
}
