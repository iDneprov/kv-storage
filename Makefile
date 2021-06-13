PORT=8080

build:
		echo $(PORT)
		docker build --tag kv-server --build-arg PORT=$(PORT) ./app
run:
		docker run --name kv-server-container -d -it -p $(PORT):8080 --rm kv-server sh
test-server:
		docker cp ./test/test.lua kv-server-container:/opt/tarantool/test.lua
		docker exec -it kv-server-container tarantool /opt/tarantool/test.lua
stop:
		docker stop kv-server-container
logs:
		docker exec -it kv-server-container cat server.log
