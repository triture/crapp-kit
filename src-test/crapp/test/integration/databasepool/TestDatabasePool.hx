package crapp.test.integration.databasepool;

import crapp.model.CrappModel.CrappModelDatabase;
import utest.Test;
import helper.kits.StringKit;
import crapp.db.DatabasePool;
import crapp.db.DatabaseError;
import crapp.model.CrappDatabaseRequestData;
import crapp.db.DatabaseSuccess;
import utest.Assert;
import utest.Async;

class TestDatabasePool extends Test {

    private var databaseModel:CrappModelDatabase;
    private var pool:DatabasePool;
    private var testTable:String;

    function setup() {
        this.testTable = 'test_${StringKit.generateRandomHex(6)}';

        this.databaseModel = {
            host : 'mysql',
            user : 'root',
            password : '',
            port : 3306,
            max_connections : 3,
            acquire_timeout : 150
        }

        this.pool = new DatabasePool(this.databaseModel);
    }

    function teardown() {
        this.pool.close();
    }

    function test_get_an_ticket_and_check_if_its_open(async:Async) {
        // ARRANGE
        var resultTicket:String;
        var resultTicketStatus:Bool;
        var expectedTicketStatus:Bool = true;
        var assert:()->Void;

        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            resultTicket = ticket;
            resultTicketStatus = this.pool.isOpen(ticket);

            assert();
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedTicketStatus, resultTicketStatus);

            async.done();
        }

    }

    function test_ticket_should_not_be_opened_after_close_ticket(async:Async) {
        // ARRANGE
        var resultTicket:String;
        var resultTicketStatus:Bool;
        var expectedTicketStatus:Bool = false;
        var assert:()->Void;

        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            resultTicket = ticket;

            this.pool.closeTicket(resultTicket);

            resultTicketStatus = this.pool.isOpen(ticket);

            assert();
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedTicketStatus, resultTicketStatus);

            async.done();
        }

    }

    function test_run_a_simple_query_and_check_result(async:Async) {
        // ARRANGE
        var resultDataValue:Int;
        var resultLength:Int;
        var expectedDataValue:Int = 1;
        var expectedLength:Int = 1;
        var assert:()->Void;
        var query:CrappDatabaseRequestData = {
            query : 'SELECT :value AS `value`',
            data : {
                value : 1
            }
        }

        // ACT
        this.pool.getTicket(function(ticket:String):Void {

            this.pool.query(
                ticket,
                query,
                function(data:DatabaseSuccess<{value:Int}>):Void {
                    resultDataValue = data.raw.next().value;
                    resultLength = data.length;

                    assert();
                }
            );

        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedDataValue, resultDataValue);
            Assert.equals(expectedLength, resultLength);
            async.done();
        }

    }

    function test_run_a_malformated_query_and_check_error(async:Async) {
        // ARRANGE
        var resultErrorCode:String;
        var expectedErrorCode:String = 'ER_PARSE_ERROR';
        var assert:()->Void;

        var query:CrappDatabaseRequestData = {
            query : 'invalid query'
        }

        // ACT
        this.pool.getTicket(function(ticket:String):Void {

            this.pool.query(
                ticket,
                query,
                function(data:DatabaseSuccess<{value:Int}>):Void {},
                function(error:DatabaseError):Void {
                    resultErrorCode = error.code;
                    assert();
                }
            );

        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedErrorCode, resultErrorCode);
            async.done();
        }

    }

    function test_a_connection_that_take_too_much_time_to_return_to_pool(async:Async) {
        // ARRANGE
        var resultErrorCode:String;
        var expectedErrorCode:String = DatabasePool.ERROR_INVALID_TICKET;
        var assert:()->Void;
        var query:CrappDatabaseRequestData = {
            query : 'SELECT 1'
        }

        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            haxe.Timer.delay(function():Void {

                this.pool.query(
                    ticket,
                    query,
                    function(data:DatabaseSuccess<{value:Int}>):Void {},
                    function(error:DatabaseError):Void {
                        resultErrorCode = error.code;
                        assert();
                    }
                );


            }, 20);
        }, 10);

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedErrorCode, resultErrorCode);
            async.done();
        }
    }

    function test_a_long_query_with_timeout_should_fail(async:Async) {
        // ARRANGE
        var resultErrorCode:String;
        var expectedErrorCode:String = 'PROTOCOL_SEQUENCE_TIMEOUT';
        var query:CrappDatabaseRequestData = {
            query : [for (i in 0 ... 1200) '(SELECT ${i} as `val`)'].join(' UNION ALL '),
            timeout : 2
        }
        var assert:()->Void;


        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            this.pool.query(
                ticket,
                query,
                function(data:DatabaseSuccess<{value:Int}>):Void {
                    assert();
                },
                function(error:DatabaseError):Void {
                    resultErrorCode = error.code;
                    assert();
                }
            );
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedErrorCode, resultErrorCode);
            async.done();
        }

    }

    function test_create_three_tickets_and_shoud_be_success(async:Async):Void {
        // ARRANGE
        var totalTicket:Int = 3;

        // ACT
        for (i in 0 ... totalTicket) {
            async.branch(function(a:Async):Void {
                this.pool.getTicket(function(ticket:String):Void {
                    if (this.pool.isOpen(ticket)) {
                        Assert.pass();
                        a.done();
                    }
                });
            });
        }

    }

    function test_create_four_tickets_and_shoud_fail_last_ticket(async:Async):Void {
        // ARRANGE
        var totalTicket:Int = 3;

        // ACT
        async.setTimeout(15000);

        for (i in 0 ... totalTicket) {
            async.branch(function(a:Async):Void {
                this.pool.getTicket(function(ticket:String):Void {
                    if (this.pool.isOpen(ticket)) {
                        Assert.pass();
                        a.done();
                    }
                });
            });
        }

        // LAST TICKET FAILING
        async.branch(function(a:Async):Void {
            this.pool.getTicket(function(ticket:String):Void {
                if (this.pool.isOpen(ticket) == false) {
                    Assert.pass();
                    a.done();
                }
            });
        });

    }

    function test_an_long_query_must_fail_if_it_is_closed_before_return(async:Async):Void {
        // ARRANGE
        var ticketTimeOut:Int = 5;
        var resultErrorCode:String;
        var expectedErrorCode:String = 'PROTOCOL_SEQUENCE_TIMEOUT';
        var query:CrappDatabaseRequestData = {
            query : [for (i in 0 ... 1200) '(SELECT ${i} as `val`)'].join(' UNION ALL '),
            timeout : 20
        }
        var assert:()->Void;

        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            this.pool.query(
                ticket,
                query,
                function(data:DatabaseSuccess<{value:Int}>):Void {
                    assert();
                },
                function(error:DatabaseError):Void {
                    resultErrorCode = error.code;
                    assert();
                }
            );
        }, ticketTimeOut);

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedErrorCode, resultErrorCode);
            async.done();
        }
    }

    function test_connection_is_working_in_transaction_mode(async:Async):Void {
        // ARRANGE
        var resultLength:Int;
        var expectedLength:Int = 0;
        var valueName:String = 'item name';
        var valueUnique:String = StringKit.generateRandomHex(30);
        var queryInsert:CrappDatabaseRequestData = {
            query : 'INSERT INTO tests.my_table (unq, name) VALUES (:unq, :name)',
            data : {
                unq : valueUnique,
                name : valueName
            }
        }
        var querySelect:CrappDatabaseRequestData = {
            query : 'SELECT * FROM tests.my_table WHERE unq = :unq',
            data : {
                unq : valueUnique
            }
        }
        var assert:()->Void;
        var fail:(err:DatabaseError)->Void = function(err:DatabaseError):Void {
            Assert.fail(err.message);
            async.done();
        }

        // ACT
        this.pool.getTicket(function(ticket_a:String):Void {
            this.pool.getTicket(function(ticket_b:String):Void {
                this.pool.query(ticket_a, queryInsert, function(result:DatabaseSuccess<Dynamic>):Void {
                    this.pool.query(ticket_b, querySelect, function(result:DatabaseSuccess<Dynamic>):Void {
                        resultLength = result.length;
                        assert();
                    }, fail);
                }, fail);
            });
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedLength, resultLength);
            async.done();
        }
    }

    function test_transaction_is_commited_after_close_a_ticket(async:Async):Void {
        // ARRANGE
        var doRollback:Bool = false;
        var resultLength:Int;
        var expectedLength:Int = 1;
        var valueName:String = 'item name';
        var valueUnique:String = StringKit.generateRandomHex(30);
        var queryInsert:CrappDatabaseRequestData = {
            query : 'INSERT INTO tests.my_table (unq, name) VALUES (:unq, :name)',
            data : {
                unq : valueUnique,
                name : valueName
            }
        }
        var querySelect:CrappDatabaseRequestData = {
            query : 'SELECT * FROM tests.my_table WHERE unq = :unq',
            data : {
                unq : valueUnique
            }
        }
        var assert:()->Void;
        var fail:(err:DatabaseError)->Void = function(err:DatabaseError):Void {
            Assert.fail(err.message);
            async.done();
        }

        // ACT
        this.pool.getTicket(function(ticket_a:String):Void {
            this.pool.getTicket(function(ticket_b:String):Void {
                this.pool.query(ticket_a, queryInsert, function(result:DatabaseSuccess<Dynamic>):Void {

                    this.pool.closeTicket(ticket_a, function():Void {

                        this.pool.query(ticket_b, querySelect, function(result:DatabaseSuccess<Dynamic>):Void {
                            resultLength = result.length;
                            assert();
                        }, fail);

                    }, doRollback);

                }, fail);
            });
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedLength, resultLength);
            async.done();
        }
    }

    function test_transaction_should_rollback_on_close_ticket_if_parameter_is_set(async:Async):Void {
        // ARRANGE
        var doRollback:Bool = true;
        var resultLength:Int;
        var expectedLength:Int = 0;
        var valueName:String = 'item name';
        var valueUnique:String = StringKit.generateRandomHex(30);
        var queryInsert:CrappDatabaseRequestData = {
            query : 'INSERT INTO tests.my_table (unq, name) VALUES (:unq, :name)',
            data : {
                unq : valueUnique,
                name : valueName
            }
        }
        var querySelect:CrappDatabaseRequestData = {
            query : 'SELECT * FROM tests.my_table WHERE unq = :unq',
            data : {
                unq : valueUnique
            }
        }
        var assert:()->Void;
        var fail:(err:DatabaseError)->Void = function(err:DatabaseError):Void {
            Assert.fail(err.message);
            async.done();
        }

        // ACT
        this.pool.getTicket(function(ticket_a:String):Void {
            this.pool.getTicket(function(ticket_b:String):Void {
                this.pool.query(ticket_a, queryInsert, function(result:DatabaseSuccess<Dynamic>):Void {

                    this.pool.closeTicket(ticket_a, function():Void {

                        this.pool.query(ticket_b, querySelect, function(result:DatabaseSuccess<Dynamic>):Void {
                            resultLength = result.length;
                            assert();
                        }, fail);

                    }, doRollback);

                }, fail);
            });
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedLength, resultLength);
            async.done();
        }
    }

    function test_the_same_query_with_active_cache_should_use_cache_data(async:Async):Void {
        // ARRANGE
        var resultErrorCode:String;
        var expectedErrorCode:String = 'PROTOCOL_SEQUENCE_TIMEOUT';
        var ticketTimeOut:Int = 5;
        var query:CrappDatabaseRequestData = {
            query : [for (i in 0 ... 1200) '(SELECT ${i} as `val`)'].join(' UNION ALL '),
            cache : true,
            cache_timeout : 50,
            timeout : 500
        }
        var assert:()->Void;

        // ACT
        this.pool.getTicket(function(ticket:String):Void {
            this.pool.query(ticket, query, function(success:DatabaseSuccess<Dynamic>):Void {

                query.timeout = 3; // forçar menor tempo de espera

                this.pool.query(ticket, query, function(success:DatabaseSuccess<Dynamic>):Void {

                    query.timeout = 5; // forca um tempo menor de execucao

                    haxe.Timer.delay( // espera o cache espirar
                        function():Void {
                            this.pool.query(ticket, query, function(sucess:DatabaseSuccess<Dynamic>):Void {
                                //
                            }, function(err:DatabaseError):Void {
                                resultErrorCode = err.code;
                                assert();
                            });
                        }, 60
                    );
                });
            });
        });

        // ASSERT
        assert = function():Void {
            Assert.equals(expectedErrorCode, resultErrorCode);
            async.done();
        }
    }
}
