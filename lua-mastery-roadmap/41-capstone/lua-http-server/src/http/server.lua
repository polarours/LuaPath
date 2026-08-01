-- server.lua — TCP server with coroutine-based connection handling.
-- Uses Lua coroutines for lightweight concurrency — one coroutine per
-- client connection, yielding when waiting on I/O and resuming when data arrives.
-- This simulates async behavior without external libraries.

-- Set up module path when run directly
if arg and arg[0]:match("server.lua") then
  package.path = "./../?.lua;./?.lua;" .. package.path
end

local Request = require("request")
local Response = require("response")

local Server = {}
Server.__index = Server

--- Create a new Server instance.
-- In production, this would use luasocket or lua-socket.
-- Here we provide a simulation framework that demonstrates the pattern.
function Server.new(app)
  local self = setmetatable({
    app = app,
    connections = {},       -- active connections (weak table for GC)
    running = false,
    _host = "127.0.0.1",
    _port = 8080,
  }, Server)
  return self
end

--- Configure host and port.
function Server:configure(host, port)
  self._host = host or self._host
  self._port = port or self._port
  return self
end

--- Simulate receiving raw HTTP requests from a client.
-- This is useful for testing without a real network stack.
function Server:simulate_request(raw_request, client_id)
  client_id = client_id or ("simulated-" .. tostring(#self.connections))

  -- Create a coroutine for this request
  local co = coroutine.create(function()
    local request = Request.parse(raw_request)

    -- Run through middleware pipeline then router
    local response = self.app:handle_raw(raw_request)

    -- Return the serialized response
    return tostring(response)
  end)

  -- Track this connection
  self.connections[#self.connections + 1] = {
    id = client_id,
    coroutine = co,
    created_at = os.time(),
  }

  -- Run the coroutine to completion
  local ok, result = coroutine.resume(co)
  if ok then
    return result
  else
    return ("Error: %s"):format(tostring(result))
  end
end

--- Simulate multiple concurrent requests.
-- Demonstrates that coroutines can handle requests concurrently
-- by suspending and resuming as needed.
function Server:simulate_concurrent(requests)
  local results = {}
  local threads = {}

  for i, req in ipairs(requests) do
    local co = coroutine.create(function()
      return self:simulate_request(req.raw, req.id)
    end)
    threads[i] = co
  end

  -- Interleave execution (round-robin)
  local idx = 1
  while #threads > 0 do
    local co = threads[idx]
    if co then
      local ok, result = coroutine.resume(co)
      if ok then
        results[#results + 1] = result
      end
      threads[idx] = nil  -- Remove completed thread
    end
    idx = (idx % #requests) + 1
  end

  return results
end

--- Get number of currently tracked connections.
function Server:connection_count()
  return #self.connections
end

--- Close all simulated connections.
function Server:close_all()
  self.connections = {}
  return self
end

--- Generate a human-readable summary of the server state.
function Server:summary()
  local lines = {}
  lines[1] = "=== Server Summary ==="
  lines[2] = ("Host: %s"):format(self._host)
  lines[3] = ("Port: %d"):format(self._port)
  lines[4] = ("Active connections: %d"):format(#self.connections)
  lines[5] = ("App routes: %d"):format(
    self.app:router() and self.app:router():count() or 0
  )
  return table.concat(lines, "\n")
end

return Server
