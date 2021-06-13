FROM tarantool/tarantool:2

COPY ./ /opt/tarantool
WORKDIR /opt/tarantool

RUN apk add --virtual .build-deps gcc g++ make cmake git
RUN tarantoolctl rocks install http

ENTRYPOINT ["tarantool", "server.lua"]
