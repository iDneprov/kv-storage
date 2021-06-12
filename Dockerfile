FROM tarantool/tarantool:2.7

ENV KV_ADRES 127.0.0.1
ENV KV_PORT 8080

RUN chmod +x installLibs.sh
RUN ./installLibs.sh
RUN tarantoolctl rocks install http

CMD [ "tarantool", "app/server.lua"]