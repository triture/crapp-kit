package crapp.model;

import anonstruct.AnonStruct;

typedef CrappServiceResultPage = {
    var itens_per_page:Int;
    var itens_total:Int;
    var page_total:Int;
    var page_current:Int;
}

class CrappServiceResultPageValidator extends AnonStruct {

    public function new() {
        super();

        this.propertyInt('itens_per_page')
        .refuseNull()
        .greaterOrEqualThan(0);

        this.propertyInt('itens_total')
        .refuseNull()
        .greaterOrEqualThan(0);

        this.propertyInt('page_total')
        .refuseNull()
        .greaterOrEqualThan(0);

        this.propertyInt('page_current')
        .refuseNull()
        .greaterOrEqualThan(0);
    }
}