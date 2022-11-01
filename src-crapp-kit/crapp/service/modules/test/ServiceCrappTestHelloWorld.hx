package crapp.service.modules.test;

class ServiceCrappTestHelloWorld extends CrappService<String> {

    override public function run():Void {
        this.resultSuccess('Hello World');
    }

}
