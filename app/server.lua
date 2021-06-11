#!/usr/bin/env tarantool

local http_router = require('http.router')
local http_server = require('http.server')
local log = require('log')

local server = http_server.new(nil, 8080)
local router = http_router.new()

box.cfg {
    log = 'server.log'
}

box.once('create', function()
    box.schema.space.create('kv_store')
    box.space.kv_store:format({
        { name = 'key', type = 'string' },
        { name = 'value', type = 'string' }
    })
    box.space.kv_store:create_index('primary',
            { type = 'hash', parts = { 1, 'string' } })
end)

local function render_error(request, status, error)
  resp = request:render{json = { error = error }}
  resp.status = status
  log.info(error)
  return resp
end

local function get_json_body(request)
  local isCorrect
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

local function new(request)
  local key, resp, body

  body, resp = get_json_body(request)
  if body == nil then
  	return resp
  end
  if body['key'] == nil then
    return render_error(request, 400, 'JSON_ERROR: JSON body have empty value')
  end
  log.info("get(key: %s)" , key)
  resp = request:render{json = {key = key, value = 'body'}}
	resp.status = 200
  return resp
end

local function change(request)
  local key, resp, body

  key = request:stash('key')
  body, resp = get_json_body(request)
  if body == nil then
  	return resp
  end
  log.info("get(key: %s)" , key)
  resp = request:render{json = {key = key, value = 'body'}}
	resp.status = 200
  return resp
end

local function get(request)
  local key, resp

  key = request:stash('key')
  log.info("get(key: %s)" , key)
  resp = request:render{json = {key = key, value = 'get'}}
	resp.status = 200
  return resp
end

local function delete(request)
  local key, resp

  key = request:stash('key')
  log.info("delite(key: %s)" , key)
  resp = request:render{json = {key = key, value = 'delete'}}
	resp.status = 200
  return resp
end

server:set_router(router)
router:route({ path = '/kv', method = 'POST' }, new)
router:route({ path = '/kv/:key', method = 'PUT' }, change)
router:route({ path = '/kv/:key', method = 'GET' }, get)
router:route({ path = '/kv/:key', method = 'DELETE' }, delete)

server:start()
