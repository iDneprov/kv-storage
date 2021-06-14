PORT=80
IMAGE_NAME=kv-stor-image
CONTAINER_NAME=kv-stor-container

build:
		docker build --tag $(IMAGE_NAME) --build-arg PORT=$(PORT) ./app
run:
		docker run --name $(CONTAINER_NAME) -d -it -p $(PORT):80 --rm $(IMAGE_NAME) sh
test-server:
		docker cp ./test/test.lua $(CONTAINER_NAME):/opt/tarantool/test.lua
		docker exec -it $(CONTAINER_NAME) tarantool /opt/tarantool/test.lua
logs:
		docker exec -it $(CONTAINER_NAME) cat server.log
stop:
		docker stop $(CONTAINER_NAME)
