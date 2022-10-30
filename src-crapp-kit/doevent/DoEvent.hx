package doevent;

class DoEvent<T> {

    public var eventType:String;
    public var data:T;

    public function new(eventType:String, data:T) {
        this.eventType = eventType;
        this.data = data;
    }

}
