package doevent;

class DoEvent<T> {

    public var eventType:String;
    public var data:T;
    public var action:(event:DoEvent<T>)->Void;

    public function new(eventType:String, data:T) {
        this.eventType = eventType;
        this.data = data;
    }

    public function clone():DoEvent<T> {
        return new DoEvent<T>(this.eventType, this.data);
    }

}
