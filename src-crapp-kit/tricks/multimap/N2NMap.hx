package tricks.multimap;

class N2NMap<K:{}, V:{}> {

    private var mapKV:ArrayMap<K, V>;
    private var mapVK:ArrayMap<V, K>;

    public function new() {
        this.mapKV = new ArrayMap<K, V>();
        this.mapVK = new ArrayMap<V, K>();
    }

    public function add(key:K, value:V):Void {
        this.mapKV.add(key, value);
        this.mapVK.add(value, key);
    }

    public function uniqueKeys():Array<K> return this.mapKV.keys();
    public function uniqueValues():Array<V> return this.mapVK.keys();

    public function getKeys(value:V):Array<K> return this.mapVK.getValues(value);
    public function getValues(key:K):Array<V> return this.mapKV.getValues(key);

    public function removeValue(key:K, value:V):Void {
        this.mapKV.removeValue(key, value);
        this.mapVK.removeValue(value, key);
    }
}
