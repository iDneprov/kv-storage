# kv-хранилище, доступное по HTTP
Приложение реализовано на языке *Lua*, сервере приложений и базе данных *Tarantool* и упаковано при помощи *Docker*.  
Также приложение запущено в *Google Cloud* и **было** доступно по адресу: https://run-6lx7zxytwq-uc.a.run.app/kv

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


## BASH команды для ручной проверки приложения на сервере:
```
curl -d '{"key":"key", "value": "value"}' -H "Content-Type: application/json" -X POST https://run-6lx7zxytwq-uc.a.run.app/kv

curl -d '{"value": "new value"}' -H "Content-Type: application/json" -X PUT https://run-6lx7zxytwq-uc.a.run.app/kv/key

curl -X GET https://run-6lx7zxytwq-uc.a.run.app/kv/key
curl -X DELETE https://run-6lx7zxytwq-uc.a.run.app/kv/key
```
