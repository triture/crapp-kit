package node.helper;

import haxe.Http;
import helper.kits.StringKit;

class Sendgrid {

    private var sendgridToken:String;

    public function new(token:String) {
        this.sendgridToken = token;
    }

    public function sendMail(envelope:SendgridEnvelope, onResult:(status:Bool)->Void):Void {

        var http:Http = new Http('https://api.sendgrid.com/v3/mail/send');
        http.addHeader('authorization', 'Bearer ${this.sendgridToken}');
        http.addHeader('content-type', 'application/json');

        var personalizationData:Dynamic = {
            to : [
                {
                    email: envelope.destinationEmail,
                    name: envelope.destinationName
                }
            ]
        }

        if (!StringKit.isEmpty(envelope.subject)) personalizationData.subject = envelope.subject;


        if (envelope.templatePersonalization != null) {
            var isDynamicTemplate:Bool = StringTools.startsWith(envelope.templateId, 'd-');

            if (isDynamicTemplate) Reflect.setField(personalizationData, 'dynamic_template_data', envelope.templatePersonalization);
            else {
                var substitutionToken:String = ":";
                var substitutionData:Dynamic = {}

                for (field in Reflect.fields(envelope.templatePersonalization)) {
                    Reflect.setField(substitutionData, '${substitutionToken}${field}', Reflect.field(envelope.templatePersonalization, field));
                }

                Reflect.setField(personalizationData, 'substitutions', substitutionData);
            }
        }

        var data:Dynamic = {
            personalizations: [personalizationData],

            from: {
                email: envelope.senderEmail,
                name: envelope.senderName
            },

            reply_to: {
                email: StringKit.isEmpty(envelope.replyEmail) ? envelope.senderEmail : envelope.replyEmail,
                name: StringKit.isEmpty(envelope.replyName) ? envelope.senderName : envelope.replyName
            },

            mail_settings : {
                bypass_list_management : {
                    enable : envelope.forceSend
                }
            },

            template_id : envelope.templateId,
        }

        if (envelope.attachments != null && envelope.attachments.length > 0) {
            Reflect.setField(data, 'attachments', envelope.attachments);
        }

        http.onError = function(resultMessage:String):Void {
            #if !production
            var errorMessage:String = StringKit.isEmpty(http.responseData) ? resultMessage : http.responseData;
            trace('-------------- SENDGRID ERROR >> START ');
            trace(errorMessage);
            trace('-------------- SENDGRID ERROR >> END');
            #end
            onResult(false);
        };
        http.onData = function(resultMessage:String):Void {
            onResult(true);
        };

        http.setPostData(haxe.Json.stringify(data));

        try {
            http.request(true);
        } catch (e:Dynamic) {
            trace(Std.string(e));
            onResult(false);
        }
    }


}

// https://sendgrid.com/docs/API_Reference/api_v3.html

typedef SendgridEnvelope = {
    var destinationEmail:String;
    var destinationName:String;
    var senderEmail:String;
    var senderName:String;
    var subject:String;
    var templateId:String;
    var forceSend:Bool;

    @:optional var attachments:Array<SendgridAttachment>;
    @:optional var replyEmail:String;
    @:optional var replyName:String;
    @:optional var templatePersonalization:Dynamic;
}

typedef SendgridAttachment = {
    var content:String;
    var filename:String;
    @:optional var type:String;

}