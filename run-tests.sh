#!/bin/bash

if [ "$HAXE_DOCKER_CONTAINER" != "1" ] ; then
    cd ./docker
    docker-compose exec haxe bash run-tests.sh
    
    exit 0
fi

echo "BUILDING CRAPP KIT UNIT TEST"           && \
haxe build-crapp-kit-tests-unit.hxml          && \
sleep 1s                                      && \
node ./build/crapp-unit-test.js
