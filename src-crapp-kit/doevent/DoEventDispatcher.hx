package doevent;

import haxe.ds.StringMap;

class DoEventDispatcher {

    private var dispatchEventMap:StringMap<Array<(eventCaller:DoEvent<Dynamic>)->Void>>;

    public function new() {
        this.free();
    }

    public function addListener<T>(eventType:String, listener:(event:DoEvent<T>)->Void):Void {
        this.createListenerEventSlot(eventType);
        this.dispatchEventMap.get(eventType).push(cast listener);
    }

    public function removeListener<T>(eventType:String, listener:(event:DoEvent<T>)->Void):Void {
        var callers:Array<(eventCaller:DoEvent<T>)->Void> = cast this.dispatchEventMap.get(eventType);

        if (callers != null) {
            while (callers.indexOf(listener) > -1) {
                callers.remove(listener);
            }

            if (callers.length == 0) {
                this.dispatchEventMap.remove(eventType);
            }
        }
    }

    private function createListenerEventSlot(event:String):Void {
        if (!this.dispatchEventMap.exists(event)) {
            this.dispatchEventMap.set(event, []);
        }
    }

    public function dispatchEvent<T>(event:DoEvent<T>):Void {
        var callers:Array<(eventCaller:DoEvent<T>)->Void> = cast this.dispatchEventMap.get(event.eventType);

        if (callers != null) {
            for (caller in callers) if (caller != null) caller(event);
        }
    }

    public function free():Void {
        this.dispatchEventMap = new StringMap<Array<(eventCaller:DoEvent<Dynamic>)->Void>>();
    }

}
