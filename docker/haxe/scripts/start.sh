#!/bin/bash

echo "haxe container"

haxelib setup /haxelib
yes | haxelib install datetime
yes | haxelib install PBKDF2
yes | haxelib install haxe-crypto
yes | haxelib install utest
yes | haxelib git hxnodejs https://github.com/HaxeFoundation/hxnodejs.git
yes | haxelib dev utilkit /repo/utilkit
yes | haxelib dev anonstruct /repo/anonstruct