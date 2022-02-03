package node.helper;

import helper.kits.DateKit;
import helper.kits.StringKit;
import abstracts.AbstractDateTimeFormat;
import abstracts.AbstractDateTimeUTCFormat;
import js.node.Process;
import js.node.ChildProcess;
import js.node.Buffer;
import js.node.ChildProcess.ChildProcessExecError;
import haxe.extern.EitherType;

class Terminale {

    private var key:String;
    private var index:Int;
    private var routines:Array<TerminaleRoutine>;

    private var __isFinished:Bool;

    public var onFinish:()->Void;
    public var onStep:()->Void;

    public function new(key:String) {
        this.key = key;
        this.index = -1;
        this.routines = [];
        this.__isFinished = false;
    }

    public function start():Void {
        if (this.hasStarted()) return;
        this.runNext();
    }

    public function isFinished():Bool return this.__isFinished;

    public function isSuccess():Bool {
        for (routine in this.routines) if (!routine.log.success) return false;
        return true;
    }

    public function getLog():Array<TerminaleLog> {
        return [for (routine in this.routines) routine.log];
    }

    private function hasStarted():Bool return this.index >= 0;

    public function addRoutine(title:String, workDir:String, command:String):Void {
        this.addJob(title, this.runTerminalCommand.bind(workDir, command, 0));
    }

    public function addJob(title:String, job:(done:JobDone)->Void):Void {
        if (this.hasStarted()) return;

        var routine:TerminaleRoutine = {
            log : {
                title : title,
                execution_start : null,
                execution_end : null,
                success : false,
                output : '** NOT EXECUTED **'
            },
            job : job

        }

        this.routines.push(routine);
    }

    private function executeRoutine(routine:TerminaleRoutine):Void {
        routine.log.execution_start = Date.now();

        Sys.println('TERMINALE ${this.key} :: ' + routine.log.execution_start + ' -- ' + routine.log.title);

        routine.job(function(success:Bool, output:String):Void {
            routine.log.execution_end = Date.now();
            routine.log.output = output;
            routine.log.success = success;

            if (success) runNext();
            else runEnd();
        });
    }

    private function runTerminalCommand(workDir:String, command:String, timeout:Int, done:JobDone):Void {

        var processOptions:Dynamic = {}

        if (!StringKit.isEmpty(workDir)) processOptions.cwd = workDir;
        if (timeout != null && timeout > 0) processOptions.timeout = timeout;

        ChildProcess.exec(
            command,
            processOptions,
            function(error:Null<ChildProcessExecError>, stdout:EitherType<Buffer, String>, stderr:EitherType<Buffer, String>):Void {

                var success:Bool = (error == null);
                var output:String = Std.string(stdout);

                done(success, output);

            }
        );
    }

    private function runNext():Void {
        this.index ++;

        if (this.index < this.routines.length) {
            if (this.onStep != null) this.onStep();
            this.executeRoutine(this.routines[this.index]);
        } else this.runEnd();
    }

    private function runEnd():Void {
        Sys.println('TERMINALE ${this.key} :: End Routines');
        this.__isFinished = true;
        if (this.onFinish != null) this.onFinish();
    }

}

typedef JobDone = (success:Bool, output:String)->Void;

private typedef TerminaleRoutine = {
    var job:(done:JobDone)->Void;
    var log:TerminaleLog;
}

typedef TerminaleLog = {
    var title:String;
    var execution_start:AbstractDateTimeFormat;
    var execution_end:AbstractDateTimeFormat;
    var success:Bool;
    var output:String;
}