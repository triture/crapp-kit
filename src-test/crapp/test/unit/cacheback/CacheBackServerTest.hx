package crapp.test.unit.cacheback;

import haxe.io.Path;
import haxe.Timer;
import tricks.cacheback.CacheBackServer;
import utest.Assert;
import utest.Async;
import utest.Test;

class CacheBackServerTest extends Test {

    var cachePath:String = '/APPLICATION-CACHE-BACK/cacheback.data';

    function setup() {
        if (sys.FileSystem.exists(cachePath)) sys.FileSystem.deleteFile(cachePath);
    }


    function test_cachebackserver_should_be_initialized_and_create_cache_file() {
        // ARRANGE
        var expected:Bool = true;
        var result:Bool;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        result = sys.FileSystem.exists(this.cachePath);

        // ASSERT
        Assert.equals(expected, result);
    }


    function test_set_and_retreive_cache_data() {
        // ARRANGE
        var cacheKey:String = 'key';
        var cacheValue:String = 'Hello World';

        var expectedValue:String = 'Hello World';
        var result:String;


        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        cache.set(cacheKey, cacheValue);

        result = cache.get(cacheKey);

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_set_and_retreive_null_value_after_timeout_expire(async:Async) {
        // ARRANGE
        var timeout:Int = 5; //ms
        var cacheKey:String = 'key';
        var cacheValue:String = 'Hello World';

        var expectedValue:String = null;
        var result:String;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath, timeout);
        cache.set(cacheKey, cacheValue);

        Timer.delay(function():Void {
            result = cache.get(cacheKey);

            // ASSERT
            Assert.equals(expectedValue, result);

            async.done();
        }, 7);
    }

    function test_set_should_reset_timeout_expiration(async:Async) {
        // ARRANGE
        var timeout:Int = 10; //ms
        var cacheKey:String = 'key';
        var cacheValue:String = 'Hello World';
        var cacheValue2:String = 'Hello World 2';

        var expectedValue:String = 'Hello World 2';
        var result:String;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath, timeout);
        cache.set(cacheKey, cacheValue);

        Timer.delay(function():Void {
            cache.set(cacheKey, cacheValue2);

            Timer.delay(function():Void {
                result = cache.get(cacheKey);

                // ASSERT
                Assert.equals(expectedValue, result);

                async.done();
            }, 8);
        }, 8);
    }

    function test_insert_two_items_and_cache_length_should_be_two() {
        // ARRANGE
        var expectedValue:Int = 2;
        var result:Int;


        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        cache.set('a', 'a');
        cache.set('b', 'b');

        result = cache.length;

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_insert_two_items_with_same_key_and_cache_length_should_be_one() {
        // ARRANGE
        var expectedValue:Int = 1;
        var result:Int;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        cache.set('a', 'a1');
        cache.set('a', 'a2');

        result = cache.length;

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_insert_two_items_for_disk_persistence_and_check_persistence_data() {
        // ARRANGE
        var expectedValue:String = 'CACHE\n["a","a"]\n["b","b"]';
        var result:String;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        cache.set('a', 'a');
        cache.set('b', 'b');
        cache.persists();

        result = sys.io.File.getContent(this.cachePath);

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_insert_two_items_for_disk_persistence_and_new_cache_must_read_from_persistence() {
        // ARRANGE
        var expectedValue:Int = 2;
        var result:Int;

        // ACT
        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        cache.set('a', 'a');
        cache.set('b', 'b');
        cache.persists();

        var cache2:CacheBackServer = new CacheBackServer(this.cachePath);
        result = cache2.length;

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_load_breaked_cache_and_ignore_mal_formated_items() {
        // ARRANGE
        var breakedCacheContent:String = 'CACHE\n["a","a"]\n["b","b';

        var expectedValue:Int = 1;
        var result:Int;

        // ACT
        sys.FileSystem.createDirectory(Path.directory(this.cachePath));
        sys.io.File.saveContent(this.cachePath, breakedCacheContent);

        var cache:CacheBackServer = new CacheBackServer(this.cachePath);
        result = cache.length;

        // ASSERT
        Assert.equals(expectedValue, result);
    }

    function test_ignore_chache_when_cache_key_changes() {
        // ARRANGE
        var oldCacheContent:String = 'CACHE\n["a","a"]\n["b","b"]';

        var expectedValue:Int = 0;
        var result:Int;

        // ACT
        sys.FileSystem.createDirectory(Path.directory(this.cachePath));
        sys.io.File.saveContent(this.cachePath, oldCacheContent);

        var cache:CacheBackServer = new CacheBackServer(this.cachePath, 'KEY2');
        result = cache.length;

        // ASSERT
        Assert.equals(expectedValue, result);
    }

}
