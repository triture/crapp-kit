package crapp.model.modules.logs;

@:enum
abstract CrappLogSituation(String) from String to String {
    var SUCCESS = 'SUCCESS';
    var ERROR = 'ERROR';
}
