
cd docker
docker-compose up -d
docker-compose exec haxe bash -c "haxe crapp-kit-test.hxml && node ./build/crapp-unit-test.js"