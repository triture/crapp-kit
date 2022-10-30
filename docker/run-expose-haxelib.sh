#!/bin/bash

if [ "$HAXE_DOCKER_CONTAINER" != "1" ] ; then
    docker-compose exec haxe bash ./docker/run-expose-haxelib.sh
    exit 0
fi

cp -rf /haxelib ./build/haxelib