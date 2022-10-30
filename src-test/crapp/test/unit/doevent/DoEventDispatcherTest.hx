package crapp.test.unit.doevent;

import doevent.DoEvent;
import doevent.DoEventDispatcher;
import utest.Assert;
import utest.Test;

class DoEventDispatcherTest extends Test {

    function test_dispatch_hello_event_passing_an_value():Void {
        // ARRANGE
        var event:DoEvent<String>;
        var eventType:String;
        var dispatcher:DoEventDispatcher;
        var listenerFunction:(event:DoEvent<String>)->Void;
        var expectedResult:String = 'WORLD';
        var result:String;

        eventType = 'HELLO';
        event = new DoEvent<String>(eventType, 'WORLD');
        listenerFunction = function(event:DoEvent<String>):Void {
            result = event.data;
        }

        // ACT
        dispatcher = new DoEventDispatcher();
        dispatcher.addListener(eventType, listenerFunction);
        dispatcher.dispatchEvent(event);

        // ASSERT
        Assert.equals(expectedResult, result);
    }

    function test_add_dispatcher_two_times_and_count_twice():Void {
        // ARRANGE
        var event:DoEvent<Any>;
        var eventType:String;
        var dispatcher:DoEventDispatcher;
        var listenerFunction:(event:DoEvent<Any>)->Void;
        var count:Int;
        var expectedResult:Int = 2;
        var result:Int ;

        count = 0;
        eventType = 'HELLO';
        event = new DoEvent<Any>(eventType, null);
        listenerFunction = function(event:DoEvent<Any>):Void {
            count++;
        }

        // ACT
        dispatcher = new DoEventDispatcher();

        dispatcher.addListener(eventType, listenerFunction);
        dispatcher.addListener(eventType, listenerFunction);

        dispatcher.dispatchEvent(event);

        result = count;

        // ASSERT
        Assert.equals(expectedResult, result);
    }

    function test_event_should_not_be_fired_after_removed_from_dispatcher():Void {
        // ARRANGE
        var event:DoEvent<Any>;
        var eventType:String;
        var dispatcher:DoEventDispatcher;
        var listenerFunction:(event:DoEvent<Any>)->Void;
        var count:Int;
        var expectedResult:Int = 1;
        var result:Int ;

        count = 0;
        eventType = 'HELLO';
        event = new DoEvent<Any>(eventType, null);
        listenerFunction = function(event:DoEvent<Any>):Void {
            count++;
        }

        // ACT
        dispatcher = new DoEventDispatcher();
        dispatcher.addListener(eventType, listenerFunction);
        dispatcher.dispatchEvent(event); // must fire event

        dispatcher.removeListener(eventType, listenerFunction);
        dispatcher.dispatchEvent(event); // should not fire event

        result = count;

        // ASSERT
        Assert.equals(expectedResult, result);
    }

}
