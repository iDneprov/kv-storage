#!/usr/bin/env tarantool

-- Подгружаем необходимые модули
local client = require('http.client')
local tap = require('tap')
local json = require('json')

-- Инициализируем taptest и выводим сообщение о начале тестирования
local taptest = tap.test('kv-storage-test')
taptest:plan(4)
taptest:diag("KV-storage test")

-- Задаем адрес сервиса
local adress = 'http://127.0.0.1:8081/kv/'


-- Функция запуска тестов
local function test_cases(data)
    local testsNum, request, test
    testsNum = table.getn(data)
    taptest:plan(testsNum)
    for i = 1, testsNum do
        test = data[i]
        taptest:diag("%s method test №%d", test['method'], i)
        request = client.request(test['method'], test['adress'], test['jsonRequest'])
        taptest:is(request.status, test['status'], 'status')
        taptest:is(request.body, test['jsonAnswer'], 'json answer')
    end
end

-- Тесты для метода POST
taptest:test('Method POST', function(test)
    local cases = {
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({ key = 'key', value = 'value'}),
            status = 200,
            jsonAnswer = json.encode({ message = 'OK'})
        },
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({ key = 'key', value = 'value'}),
            status = 409,
            jsonAnswer = json.encode({ error = 'STORAGE_ERROR: trying to insert set with existing key'}),
        },
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({ key = 'key'}),
            status = 400,
            jsonAnswer = json.encode({ error = 'JSON_ERROR: JSON body have empty key or value'})
        },
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({ value = 'value'}),
            status = 400,
            jsonAnswer = json.encode({ error = 'JSON_ERROR: JSON body have empty key or value'}),
        },
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({}),
            status = 400,
            jsonAnswer = json.encode({ error = 'JSON_ERROR: JSON body have empty key or value'}),
        },
        {
            method = 'post',
            adress = adress,
            jsonRequest = json.encode({ key = 'key1', value = 'value1'}),
            status = 200,
            jsonAnswer = json.encode({ message = 'OK'}),
        }
    }
    test_cases(cases)
end)

-- Тесты для метода PUT
taptest:test('Method PUT', function(test)
    local cases = {
        {
            method = 'put',
            adress = adress .. 'key',
            jsonRequest = json.encode({ value = 'new value'}),
            status = 200,
            jsonAnswer = json.encode({ value = 'value'})
        },
        {
            method = 'put',
            adress = adress .. 'key',
            jsonRequest = json.encode({ value = 'super new value'}),
            status = 200,
            jsonAnswer = json.encode({ value = 'new value'})
        },
        {
            method = 'put',
            adress = adress .. 'not-key',
            jsonRequest = json.encode({ value = 'super new value'}),
            status = 404,
            jsonAnswer = json.encode({ error = 'STORAGE_ERROR: trying to change value with non-existent key'})
        },
        {
            method = 'put',
            adress = adress .. 'key',
            jsonRequest = json.encode({ notValue = 'super puper new value'}),
            status = 400,
            jsonAnswer = json.encode({ error = 'JSON_ERROR: JSON body have empty key or value'})
        }
    }
    test_cases(cases)
end)

-- Тесты для метода GET
taptest:test('Method GET', function(test)
    local cases = {
        {
            method = 'get',
            adress = adress .. 'key',
            jsonRequest = json.encode({}),
            status = 200,
            jsonAnswer = json.encode({ value = 'super new value'})
        },
        {
            method = 'get',
            adress = adress .. 'not-key',
            jsonRequest = json.encode({}),
            status = 404,
            jsonAnswer = json.encode({ error = 'STORAGE_ERROR: trying to get set with non-existent key'})
        },
        {
            method = 'get',
            adress = adress .. 'key1',
            jsonRequest = json.encode({}),
            status = 200,
            jsonAnswer = json.encode({ value = 'value1'})
        },
    }
    test_cases(cases)
end)

-- Тесты для метода DELETE
taptest:test('Method DELETE', function(test)
    local cases = {
        {
            method = 'delete',
            adress = adress .. 'key',
            jsonRequest = json.encode({}),
            status = 200,
            jsonAnswer = json.encode({ value = 'super new value'})
        },
        {
            method = 'delete',
            adress = adress .. 'key1',
            jsonRequest = json.encode({}),
            status = 200,
            jsonAnswer = json.encode({ value = 'value1'})
        },
        {
            method = 'delete',
            adress = adress .. 'key1',
            jsonRequest = json.encode({}),
            status = 404,
            jsonAnswer = json.encode({ error = 'STORAGE_ERROR: trying to delete set with non-existent key'})
        },
    }
    test_cases(cases)
end)
