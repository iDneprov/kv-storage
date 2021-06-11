#!/usr/bin/env tarantool

-- Подгрудаем необходимые модули
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
--    возвращает ответ с нужным статусом и записывает ошибку в логи
local function render_error(request, status, error)
  response = request:render{json = { error = error }}
  response.status = status
  log.info(error)
  return response
end

-- Функция извлечения JSON доби из ответа:
--    извлекает боди и проверяет его на наличие необходимых данных
--    возвращает либо боди, в случае наличия в нем всего необходимого,
--    либо nil и ответ
local function get_json_body(request)
  local isCorrect, body
  isCorrect, body = pcall(function() return request:json() end)
  if isCorrect then
    if type(body) == 'string' and body == nil then
      return nil, render_error(request, 400, 'JSON_ERROR: JSON body is empty')
    end
    if body['value'] == nil then
      return nil, render_error(request, 400, 'JSON_ERROR: JSON body have empty value')
    else
      return body
    end
  else
      return nil, render_error(request, 400, 'JSON_ERROR: JSON is not correct')
  end
end

-- Функця добавления нового набора ключ-значение в хранилище
local function new(request)
  local body, response, key, value, set
  body, response = get_json_body(request)
  if body == nil then
  	return response
  end
  key = body['key']
  value = body['value']
  if key == nil then
    return render_error(request, 400, 'JSON_ERROR: JSON key have empty key')
  end
  set = box.space.kv_storage:get(key)
  if set == nil then
      box.space.kv_storage:insert { key, value }
      log.info("Inserted %s", key)
      response = request:render{json = { message = "Set was inserted"}}
      response.status = 200
      return response
  else
      return render_error(request, 409, 'STORAGE_ERROR: trying to insert set with existing key')
  end
end

-- Функця изменения занчения в хранилище по ключу:
--    Возвращает предидущее значение
local function change(request)
  local key, value, newValue, set, response, body
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
  log.info("Change %s" , key)
  response = request:render{json = { value = value}}
	response.status = 200
  return response
end

local function get(request)
  local key, value, set, response
  key = request:stash('key')
  set = box.space.kv_storage:get(key)
  if set == nil then
    return render_error(request, 404, 'STORAGE_ERROR: trying to get set with non-existent key')
  end
  value = set['value']
  log.info("Get %s" , key)
  response = request:render{json = {value = value}}
	response.status = 200
  return response
end

local function delete(request)
  local key, value, set, response
  key = request:stash('key')
  set = box.space.kv_storage:get(key)
  if set == nil then
    return render_error(request, 404, 'STORAGE_ERROR: trying to delete set with non-existent key')
  end
  value = set['value']
  log.info("Delite %s", key)
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
