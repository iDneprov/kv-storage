#!/usr/bin/env tarantool
-- REST API kv-хранилище

-- Подгружаем необходимые модули
local http_router = require('http.router')
local http_server = require('http.server')
local log = require('log')

-- Вызываем конструктор для http сервера и роутера
local server = http_server.new(nil, 8080)
local router = http_router.new()

-- Задаем конфигруацию
box.cfg {
    log = 'server.log'
}

-- Задаем структуру базы данных и инициализируем её
box.once('init', function()
    box.schema.create_space('kv_storage')
    box.space.kv_storage:format({
        { name = 'key', type = 'string' },
        { name = 'value', type = 'string' }
    })
    box.space.kv_storage:create_index('primary', { type = 'hash', parts = { 1, 'str' } })
end)

-- Функция обработки ошибок:
--      возвращает ответ с нужным статусом и записывает ошибку в логи
local function render_error(request, status, error)
    response = request:render{json = { error = error }}
    response.status = status
    log.info(error)
    return response
end

-- Функция извлечения JSON доби из ответа:
--      если в боди нет значения, возвращает nil и ответ со статусом 400 и описанием ошибки
--      в остальных случаях возвращает боди
local function get_json_body(request)
    local isCorrect, body
    isCorrect, body = pcall(function() return request:json() end)
    if (not isCorrect) or (((type(body) == 'string') and (body == nil)) or body['value'] == nil) then
            return nil, render_error(request, 400, 'JSON_ERROR: JSON body have empty key or value')
        else
            return body
        end
end

-- Функця добавления нового набора ключ-значение в хранилище:
--      если в боди нет ключа, либо значения, возвращает ответ со статусом 400 и описанием ошибки
--      если ключ уже есть в хранилище, возвращает ответ со статусом 409 и описанием ошибки
--      в осатльных случах вставляет пару ключ-занчение и возвращает ответ со статусом 200
local function new(request)
    local body, response, key, value, set
    log.info('New')
    body, response = get_json_body(request)
    if body == nil then
    	return response
    end
    key = body['key']
    value = body['value']
    if key == nil then
        return render_error(request, 400, 'JSON_ERROR: JSON body have empty key or value')
    end
    set = box.space.kv_storage:get(key)
    if set == nil then
        box.space.kv_storage:insert { key, value }
        log.info('ОК key: %s', key)
        response = request:render{json = { message = 'OK'}}
        response.status = 200
        return response
    else
        return render_error(request, 409, 'STORAGE_ERROR: trying to insert set with existing key')
    end
end

-- Функця изменения занчения в хранилище по ключу:
--      если в боди нет значения, возвращает ответ со статусом 400 и описанием ошибки
--      если ключа нет в хранилище, возвращает ответ со статусом 404 и описанием ошибки
--      в осатльных случах изменяет значение и возвращает ответ со статусом 200 и предидущее значение
local function change(request)
    local key, value, newValue, set, response, body
    log.info('Change')
    key = request:stash('key')
    if key == nil then
        return render_error(request, 400, 'ADRESS_ERROR: key in adress have empty value')
    end
    body, response = get_json_body(request)
    if body == nil then
        return response
    end
    newValue = body['value']
    set = box.space.kv_storage:get(key)
    if set == nil then
        return render_error(request, 404, 'STORAGE_ERROR: trying to change value with non-existent key')
    end
    value = set['value']
    box.space.kv_storage:update(key, { { '=', 2, newValue } })
    log.info('ОК key: %s' , key)
    response = request:render{json = { value = value}}
    response.status = 200
    return response
end

-- Функця получения занчения в хранилище по ключу:
--      если ключа нет в хранилище, возвращает ответ со статусом 404 и описанием ошибки
--      в осатльных случах возвращает ответ со статусом 200 и значение
local function get(request)
    local key, value, set, response
    log.info('Get', key)
    key = request:stash('key')
    set = box.space.kv_storage:get(key)
    if set == nil then
        return render_error(request, 404, 'STORAGE_ERROR: trying to get set with non-existent key')
    end
    value = set['value']
    log.info('ОК key: %s', key)
    response = request:render{json = {value = value}}
    response.status = 200
    return response
end

-- Функця удаления пары ключ-значение из хранилища по ключу:
--      если ключа нет в хранилище, возвращает ответ со статусом 404 и описанием ошибки
--      в осатльных случах удаляет пару и возвращает ответ со статусом 200 и значение
local function delete(request)
    local key, value, set, response
    log.info('Delite')
    key = request:stash('key')
    set = box.space.kv_storage:get(key)
    if set == nil then
        return render_error(request, 404, 'STORAGE_ERROR: trying to delete set with non-existent key')
    end
    value = set['value']
    log.info('ОК key: %s', key)
    box.space.kv_storage:delete(key)
    response = request:render{json = {value = value}}
    response.status = 200
    return response
end

server:set_router(router)
router:route({ path = '/kv', method = 'POST' }, new)
router:route({ path = '/kv/:key', method = 'PUT' }, change)
router:route({ path = '/kv/:key', method = 'GET' }, get)
router:route({ path = '/kv/:key', method = 'DELETE' }, delete)

server:start()
