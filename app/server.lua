#!/usr/bin/env tarantool

local http_router = require('http.router')
local http_server = require('http.server')
local log = require('log')

local server = http_server.new(nil, 8080)
local router = http_router.new()

local function get_json_body(request)
  local isCorrect
  isCorrect, body = pcall(function() return request:json() end)
  if isCorrect then
    if (type(body) ~= 'string' and body ~= nil and body['value'] ~= nil) then
      return body
    else
      log.info("Error: JSON body have empty value")
      return nil
    end
  else
      log.info("Error: JSON is not correct")
      return nil
  end
end

local function new(request)
  local key, resp, body

  body = get_json_body(request)
  if body == nil then
    resp = req:render{json = { error = 'invalid body' }}
  	resp.status = 400
  	return resp
  end
  log.info("get(key: %s)" , key)
  resp = request:render{json = {key = key, value = 'body'}}
	resp.status = 200
  return resp
end

local function change(request)
  local key, resp, body

  key = request:stash('key')
  body = get_json_body(request)
  if body == nil then
    resp = request:render{json = { error = 'invalid body' }}
  	resp.status = 400
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
