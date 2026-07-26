-- simple-server.lua — Demo of the Lua HTTP server framework.
-- This example combines all components into a working mini web application.

local script_path = arg[0]:gsub("%.lua$", "")
local dir_match = script_path:gsub("[/\\][^/\\]*$", "") .. "/../src/http"
package.path = dir_match .. "/?.lua;" .. package.path

local App = require("app")
local Server = require("server")

local App = require("app")
local Server = require("server")

--- Create the application
local app = App.new()

--- Configure the app
app:configure {
  host = "127.0.0.1",
  port = 8080,
}

--- Add middleware: logging
app:logging {
  logger = function(msg)
    print("[LOG] " .. msg)
  end,
}

--- Add middleware: CORS
app:cors("*")

--- Define routes

-- Homepage
app:get("/", function(req, res)
  return res:text("Welcome to LuaPath HTTP Server!\n\nTry /api/users/1 or /api/echo")
end)

-- Health check
app:get("/health", function(req, res)
  return res:json({ status = "ok", uptime = os.time(), framework = "LuaHTTP" })
end)

-- API user endpoint with path parameter
app:get("/api/users/:id", function(req, res)
  local user_id = req:get_route_param("id")
  return res:json({
    id = user_id,
    name = "User " .. tostring(user_id),
    email = ("user%s@luapath.dev"):format(user_id),
  })
end)

-- API users list (simulated database)
app:get("/api/users", function(req, res)
  local users = {}
  for i = 1, 5 do
    users[#users + 1] = {
      id = i,
      name = ("User %d"):format(i),
      email = ("user%d@luapath.dev"):format(i),
    }
  end
  return res:json(users)
end)

-- Echo POST endpoint
app:post("/api/echo", function(req, res)
  return res:json({
    method = req.method,
    body = req.body,
    headers = req.headers,
  })
end)

-- JSON creation endpoint
app:post("/api/items", function(req, res)
  return res:created({
    id = math.random(1000, 9999),
    data = req.body,
  })
end)

-- Search with query parameters
app:get("/api/search", function(req, res)
  local q = req:get_param("q") or ""
  local page = req:get_param("page") or "1"
  return res:json({
    query = q,
    page = tonumber(page) or 1,
    results_count = #q > 0 and math.random(10, 100) or 0,
  })
end)

-- Static file simulation
app:get("/static/:filename", function(req, res)
  local filename = req:get_route_param("filename")
  local ext = filename:match("%.([^%.]+)$")
  local content_types = {
    html = "text/html; charset=utf-8",
    css = "text/css",
    js = "application/javascript",
    json = "application/json",
    png = "image/png",
    jpg = "image/jpeg",
    svg = "image/svg+xml",
  }
  local ct = content_types[ext] or "application/octet-stream"
  return res:set_header("Content-Type", ct)
           :set_body(("-- Placeholder content for %s\n"):format(filename))
end)

-- Run the app
print("=== Configuration ===")
app:run()
print("")
print("=== Simulating Requests ===\n")

app:simulate("GET", "/")
app:simulate("GET", "/health")
app:simulate("GET", "/api/users/42")
app:simulate("POST", "/api/echo", "Hello, World!")
app:simulate("GET", "/api/search?q=lua+programming&page=2")
app:simulate("GET", "/not-existing")
app:simulate("OPTIONS", "/api/users")

print("=== Summary ===")
print(app:router():list_routes())
print("\n=== Demo Complete ===")
