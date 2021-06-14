# kv-хранилище, доступное по HTTP
Приложение реализовано на языке *Lua*, сервере приложений и базе данных *Tarantool* и упаковано при помощи *Docker*.  

## API:
```
 - POST /kv body: {key: "test", "value": {SOME ARBITRARY JSON}} 
 - PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}
 - GET kv/{id} 
 - DELETE kv/{id}
```

 - POST  возвращает 409 если ключ уже существует, 
 - POST, PUT возвращают 400 если боди некорректное
 - PUT, GET, DELETE возвращает 404 если такого ключа нет
 - все операции логируются

## Запуск приложения:

`make` — сборка  
`make run` — запуск приложения  
`make test-server` — запуск тестов  
`make logs` — просомтр логов приложения (работает только при запущенном приложении)  
`make stop` — остановка приложения   


## BASH команды для ручной проверки приложения:
```
curl -d '{"key":"key", "value": "value"}' -H "Content-Type: application/json" -X POST http://127.0.0.1:8080/kv

curl -d '{"value": "new value"}' -H "Content-Type: application/json" -X PUT http://127.0.0.1:8080/kv/key

curl -X GET http://127.0.0.1:8080/kv/key

curl -X DELETE http://127.0.0.1:8080/kv/key
```
