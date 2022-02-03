package crapp.controller;

import helper.kits.StringKit;
import haxe.crypto.Sha256;

class SecurityController {

    public function new() {

    }

    public function getRandomPassword(simplePassword:Bool, length:Int):String {
        var chars:String =
            "abcdefghijklmnopqrstuvxywz" +
            "ABCDEFGHIJKLMNOPQRSTUVXYWZ" +
            "0123456789";

        if (simplePassword) chars =
            "abcdefghjkmnpqrstuvxywz" +
            "23456789";

        return StringKit.generateRandomString(length, chars.split(''));
    }

    public function getPasswordHashed(cleanPassword:String):CrappDataPassword {
        var rounds:Int = Crapp.S.model.rounds;
        var crappPrivateKey:String = Crapp.S.model.private_key;

        var saltHash:String = Sha256.encode(StringKit.generateRandomString(400));
        var passwordHash:String = Sha256.encode(cleanPassword + crappPrivateKey + saltHash);

        for (i in 0 ... rounds) passwordHash = Sha256.encode(passwordHash);

        return {
            password_hash : passwordHash,
            salt_hash : saltHash
        }
    }

    public function validatePassword(cleanPassword:String, password:CrappDataPassword):Bool {
        var rounds:Int = Crapp.S.model.rounds;
        var crappPrivateKey:String = Crapp.S.model.private_key;

        var passwordHash:String = Sha256.encode(cleanPassword + crappPrivateKey + password.salt_hash);

        for (i in 0 ... rounds) passwordHash = Sha256.encode(passwordHash);

        return (passwordHash == password.password_hash);
    }

}


typedef CrappDataPassword = {
    var password_hash:String;
    var salt_hash:String;
}
