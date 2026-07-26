-- app.lua — Unified application facade using a DSL-style API.
-- Combines Router, MiddlewarePipeline, and utility functions into
-- a single entry point for building HTTP servers.

-- Require components lazily to avoid circular dependencies.

local Request = require("request")
local Response = require("response")
local Router = require("router").new()
local MiddlewarePipeline = require("middleware").new()

local App = {}
App.__index = App

--- Create a new Application instance.
function App.new()
  local self = setmetatable({
    _router = nil,
    _middleware_pipeline = nil,
    _version = "1.0.0",
    _started = false,
    _config = {
      host = "127.0.0.1",
      port = 8080,
    },
  }, App)
  return self
end

--- Get the internal router (lazily initialized).
function App:_ensure_router()
  if not self._router then
    self._router = Router.new()
  end
  return self._router
end

--- Get the internal middleware pipeline (lazily initialized).
function App:_ensure_pipeline()
  if not self._middleware_pipeline then
    self._middleware_pipeline = MiddlewarePipeline.new()
  end
  return self._middleware_pipeline
end

-- --- Convenience: GET route.
function App:get(path, handler)
  self:_ensure_router():get(path, handler)
  return self
end

--- Convenience: POST route.
function App:post(path, handler)
  self:_ensure_router():post(path, handler)
  return self
end

--- Convenience: PUT route.
function App:put(path, handler)
  self:_ensure_router():put(path, handler)
  return self
end

--- Convenience: DELETE route.
function App:delete(path, handler)
  self:_ensure_router():delete(path, handler)
  return self
end

--- Convenience: PATCH route.
function App:patch(path, handler)
  self:_ensure_router():patch(path, handler)
  return self
end

--- Add middleware to the pipeline.
function App:use(fn)
  self:_ensure_pipeline():use(fn)
  return self
end

--- Configure application settings.
function App:configure(settings)
  if settings.host then
    self._config.host = settings.host
  end
  if settings.port then
    self._config.port = settings.port
  end
  if settings.version then
    self._version = settings.version
  end
  return self
end

--- Handle a raw HTTP request string.
-- Returns a Response object.
function App:handle_raw(raw_request)
  local request = Request.parse(raw_request)

  -- First run middleware pipeline
  local response = self:_ensure_pipeline():execute(request)

  -- Only dispatch to router if no middleware produced a response
  if not self:_middleware_produced_response(response) then
    local router = self:_ensure_router()
    return router:route(request)
  end

  return response
end

--- Run the server (simulated mode).
-- In production, this would use Lua's socket library or luasocket.
function App:run(host, port)
  host = host or self._config.host
  port = port or self._config.port

  self._started = true
  print(("Server configured: %s:%d"):format(host, port))
  print("Version: " .. self._version)
  print("Routes: " .. tostring(self:_ensure_router():count()))
  print("Middlewares: " .. tostring(self:_ensure_pipeline():count()))
  print("")

  -- Print route listing
  print(self:_ensure_router():list_routes())
  print("")

  return self
end

--- Simulate a request and print the result.
-- Useful for testing without a running server.
function App:simulate(method, path, body, headers)
  headers = headers or {}
  headers["Host"] = self._config.host .. ":" .. self._config.port

  local raw = method .. " " .. path .. " HTTP/1.1\r\n"
  for k, v in pairs(headers) do
    raw = raw .. k .. ": " .. v .. "\r\n"
  end
  if body then
    headers["Content-Length"] = tostring(#body)
    raw = raw .. "Content-Length: " .. tostring(#body) .. "\r\n"
  end
  raw = raw .. "\r\n"
  if body then
    raw = raw .. body
  end

  local response = self:handle_raw(raw)
  print("--- " .. method .. " " .. path .. " ---")
  print(response)
  print("")

  return response
end

--- Get internal router for inspection/testing.
function App:router()
  return self:_ensure_router()
end

--- Reset the application state.
function App:reset()
  self._router = nil
  self._middleware_pipeline = nil
  self._started = false
  return self
end

--- Helper: check if middleware produced a response.
function App:_middleware_produced_response(response)
  if not response then
    return false
  end
  -- A non-empty body or non-200 status indicates a response was produced
  if response.body and #response.body > 0 then
    return true
  end
  if response.status_code and response.status_code ~= 200 then
    return true
  end
  return false
end

--- Singletons: create an app instance.
-- Allows both `local app = App()` and `local app = App()` patterns.
function App.__call(_, ...)
  return App.new(...)
end

--- Pre-built common middlewares accessible on the App table.
App.logging = function(self, opts)
  return self:_ensure_pipeline():logging(opts)
end

App.cors = function(self, origin)
  return self:_ensure_pipeline():cors(origin)
end

return App
