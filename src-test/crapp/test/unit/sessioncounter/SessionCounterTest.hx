package crapp.test.unit.sessioncounter;

import utest.Async;
import utest.Assert;
import tricks.sessioncounter.SessionCounter;
import utest.Test;

class SessionCounterTest extends Test {

    function test_validate_a_not_existent_key_should_result_zero_count() {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultCount:Int;
        var expectedCount:Int = 0;
        var valueKey:String = 'Some key';

        // ACT
        resultCount = counter.count(valueKey);

        // ASSERT
        Assert.equals(expectedCount, resultCount);
    }

    function test_add_a_key_should_count_one() {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultCount:Int;
        var expectedCount:Int = 1;
        var valueKey:String = 'Some key';

        // ACT
        counter.add(valueKey);
        resultCount = counter.count(valueKey);

        // ASSERT
        Assert.equals(expectedCount, resultCount);
    }

    function test_two_adds_on_a_key_should_count_two() {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultCount:Int;
        var expectedCount:Int = 2;
        var valueKey:String = 'Some key';

        // ACT
        counter.add(valueKey);
        counter.add(valueKey);
        resultCount = counter.count(valueKey);

        // ASSERT
        Assert.equals(expectedCount, resultCount);
    }

    function test_two_adds_on_a_key_should_count_one_after_50ms_passed(async:Async) {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultCount:Int;
        var expectedCount:Int = 1;
        var valueKey:String = 'Some key';

        // ACT
        counter.add(valueKey);
        counter.add(valueKey);

        // ASSERT
        haxe.Timer.delay(function():Void {
            resultCount = counter.count(valueKey);

            Assert.equals(expectedCount, resultCount);
            async.done();
        }, 52);
    }

    function test_adds_up_to_four_dont_breaks_the_theshold() {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultAdd:Bool;
        var expectedAdd:Bool = false;
        var valueKey:String = 'Some key';

        // ACT
        counter.add(valueKey);
        counter.add(valueKey);
        counter.add(valueKey);
        resultAdd = counter.add(valueKey);

        // ASSERT
        Assert.equals(expectedAdd, resultAdd);
    }

    function test_adds_up_to_five_breaks_the_theshold() {
        // ARRANGE
        var counter:SessionCounter = new SessionCounter();
        var resultAdd:Bool;
        var expectedAdd:Bool = true;
        var valueKey:String = 'Some key';

        // ACT
        counter.add(valueKey);
        counter.add(valueKey);
        counter.add(valueKey);
        counter.add(valueKey);
        resultAdd = counter.add(valueKey);

        // ASSERT
        Assert.equals(expectedAdd, resultAdd);
    }

}
