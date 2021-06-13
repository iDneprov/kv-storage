build:
		docker build --tag kv-server ./app
		docker build --tag kv-test ./test
		docker network create test-network
run:
		docker run --name kv-server-container -d -it -p 8080:8080 --net=test-network --rm kv-server
tst:
		docker run --name kv-test-container -it --rm --link kv-server-container --net=test-network kv-test
stop:
		docker stop kv-server-container
		docker network rm test-network
logs:
		cat server.log
