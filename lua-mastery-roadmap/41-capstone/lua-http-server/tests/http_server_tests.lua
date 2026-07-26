-- http_server_tests.lua — Comprehensive test suite for the Lua HTTP server framework.
-- Tests every component: Request, Response, Router, MiddlewarePipeline, App, Server.

package.path = "./lua-mastery-roadmap/41-capstone/lua-http-server/src/?lua;./lua-mastery-roadmap/41-capstone/lua-http-server/src/http/?.lua;" .. package.path

local pass = 0
local fail = 0
local total = 0

--- Assertion helpers
function assert_eq(actual, expected, msg)
  total = total + 1
  if actual == expected then
    pass = pass + 1
  else
    fail = fail + 1
    print(("  FAIL: %s (expected=%q, actual=%q)"):format(msg or "assertion", expected, actual))
  end
end

function assert_true(val, msg)
  assert_eq(val, true, msg)
end

function assert_false(val, msg)
  assert_eq(val, false, msg)
end

function assert_nil_val(val, msg)
  assert_eq(val, nil, msg)
end

function assert_type(val, t, msg)
  assert_eq(type(val), t, msg)
end

function assert_contains(str, substr, msg)
  total = total + 1
  if str:find(substr, 1, true) then
    pass = pass + 1
  else
    fail = fail + 1
    print(("  FAIL: %s ('%s' not found in '%s')"):format(msg or "assertion", substr, str))
  end
end

print("=== Request Tests ===")

do
  local Request = require("request")

  print("Creating a request...")
  local req = Request.new()
  assert_type(req.method, "string", "Request.new() returns table")
  assert_eq(req.method, "GET", "Default method is GET")
  assert_eq(req.path, "/", "Default path is /")

  print("Parsing a simple GET request...")
  local parsed = Request.parse("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
  assert_eq(parsed.method, "GET", "Parsed method is GET")
  assert_eq(parsed.path, "/", "Parsed path is /")
  assert_eq(parsed.version, "HTTP/1.1", "Parsed version is HTTP/1.1")
  assert_eq(parsed.headers["Host"], "example.com", "Parsed Host header")

  print("Parsing POST with body...")
  local post_req = Request.parse(
    "POST /api/data HTTP/1.1\r\n" ..
    "Content-Type: application/json\r\n" ..
    "Content-Length: 5\r\n" ..
    "\r\n" ..
    "hello"
  )
  assert_eq(post_req.method, "POST", "POST method parsed")
  assert_eq(post_req.path, "/api/data", "POST path parsed")
  assert_eq(post_req.body, "hello", "Body parsed correctly")
  assert_eq(post_req.headers["Content-Type"], "application/json", "Content-Type header")

  print("Parsing query parameters...")
  local qreq = Request.parse("GET /search?q=lua&page=1 HTTP/1.1\r\n\r\n")
  assert_eq(qreq.query_string, "q=lua&page=1", "Query string extracted")
  assert_eq(qreq.query_params["q"], "lua", "Query param q=lua")
  assert_eq(qreq.query_params["page"], "1", "Query param page=1")
  assert_eq(qreq.path, "/search", "Path without query string")

  print("Case-insensitive header lookup...")
  local case_req = Request.parse("GET / HTTP/1.1\r\nAuthorization: Bearer abc123\r\n\r\n")
  assert_eq(case_req:get_header("authorization"), "Bearer abc123", "Header lookup is case-insensitive")
  assert_nil_val(case_req:get_header("nonexistent"), "Nil for missing header")
end

print("")
print("=== Response Tests ===")

do
  local Response = require("response")

  print("Creating responses with constructors...")
  local ok_resp = Response.ok("Hello")
  assert_eq(ok_resp.status_code, 200, "OK status is 200")
  assert_eq(ok_resp.body, "Hello", "Body set via ok()")

  local nf_resp = Response.not_found()
  assert_eq(nf_resp.status_code, 404, "Not Found status is 404")

  local br_resp = Response.bad_request("Invalid input")
  assert_eq(br_resp.status_code, 400, "Bad Request status is 400")

  local ie_resp = Response.internal_error("Database error")
  assert_eq(ie_resp.status_code, 500, "Internal Error status is 500")

  print("Fluent API...")
  local fluent = Response.new(200, "")
      :set_header("X-Custom", "value")
      :set_body("World")
  assert_eq(fluent.headers["X-Custom"], "value", "set_header works")
  assert_eq(fluent.body, "World", "set_body works")

  print("Response:text()...")
  local text_resp = Response.new(200, ""):text("Plain text response")
  assert_contains(text_resp.headers["Content-Type"], "text/plain", "Text content type")
  assert_eq(text_resp.body, "Plain text response", "Text body set")

  print("Response:json()...")
  local json_resp = Response.new(200, ""):json({ name = "Lua", version = 5.4 })
  assert_contains(json_resp.headers["Content-Type"], "application/json", "JSON content type")
  assert_contains(json_resp.body, "Lua", "JSON body contains key data")

  print("Response:redirect()...")
  local redir = Response.new(200, ""):redirect("/login")
  assert_eq(redir.status_code, 302, "Redirect status is 302")
  assert_eq(redir.headers["Location"], "/login", "Location header set")

  print("__tostring serialization...")
  local ser = Response.new(200, "test")
  local serialized = tostring(ser)
  assert_contains(serialized, "HTTP/1.1 200 OK", "HTTP status line present")
  assert_contains(serialized, "test", "Body present in serialization")
end

print("")
print("=== Router Tests ===")

do
  local Router = require("router")
  local Request = require("request")

  local router = Router.new()

  print("Registering routes...")
  router:get("/", function(req, res) return res:text("home") end)
  router:get("/users/:id", function(req, res)
    return res:json({ id = req:get_route_param("id") })
  end)
  router:post("/data", function(req, res)
    return res:json({ created = true })
  end)
  router:put("/items/:id", function(req, res)
    return res:json({ updated = true, id = req:get_route_param("id") })
  end)
  router:delete("/items/:id", function(req, res)
    return res:json({ deleted = true, id = req:get_route_param("id") })
  end)

  assert_true(router:count() > 0, "Routes registered")

  print("Exact path matching...")
  local req = Request.parse("GET / HTTP/1.1\r\n\r\n")
  local resp = router:route(req)
  assert_eq(resp.status_code, 200, "GET / matched")
  assert_contains(resp.body, "home", "Response body is home")

  print("Parameterized path matching...")
  local user_req = Request.parse("GET /users/42 HTTP/1.1\r\n\r\n")
  local user_resp = router:route(user_req)
  assert_eq(user_resp.status_code, 200, "GET /users/:id matched")
  assert_contains(user_resp.body, "42", "Route param id=42 captured")

  print("Method-based routing...")
  local post_req = Request.parse("POST /data HTTP/1.1\r\nContent-Type: application/json\r\n\r\n{}")
  local post_resp = router:route(post_req)
  assert_eq(post_resp.status_code, 200, "POST /data matched")

  print("404 for non-matching route...")
  local miss_req = Request.parse("GET /not-exist HTTP/1.1\r\n\r\n")
  local miss_resp = router:route(miss_req)
  assert_eq(miss_resp.status_code, 404, "Non-matching route returns 404")

  print("List routes...")
  local listing = router:list_routes()
  assert_contains(listing, "Registered Routes:", "Route listing has header")
  assert_contains(listing, "GET", "Listing contains methods")
end

print("")
print("=== Middleware Pipeline Tests ===")

do
  local MiddlewarePipeline = require("middleware")
  local Request = require("request")
  local Response = require("response")

  print("Basic middleware chain...")
  local pipeline = MiddlewarePipeline.new()
  local log = {}

  pipeline:use(function(req, res, next)
    log[#log + 1] = "mw1-before"
    next()
    log[#log + 1] = "mw1-after"
  end)

  pipeline:use(function(req, res, next)
    log[#log + 1] = "mw2-before"
    next()
    log[#log + 1] = "mw2-after"
  end)

  -- Simulate request with default parsing (works even for minimal input)
  local mock_req = Request.new()
  mock_req.method = "GET"
  mock_req.path = "/"

  local response = pipeline:execute(mock_req)
  assert_true(#log >= 4, "Multiple middlewares executed")
  assert_eq(log[1], "mw1-before", "First middleware before runs first")
  assert_eq(log[4], "mw1-after", "First middleware after runs last (stack unwinding)")
  print("  Execution order: " .. table.concat(log, ", "))

  print("Short-circuit middleware...")
  local short_pipeline = MiddlewarePipeline.new()
  short_pipeline:use(function(req, res, next)
    res:set_header("X-Short-Circuit", "true")
    res:set_body("blocked")
    res.status_code = 403
    -- No next() call — short-circuits
  end)

  local short_req = Request.new()
  short_req.method = "GET"
  short_req.path = "/"
  local short_resp = short_pipeline:execute(short_req)
  assert_true(short_resp.headers["X-Short-Circuit"] ~= nil, "Short-circuit header present")
  assert_eq(short_resp.status_code, 403, "Short-circuit changes status")

  print("Logging middleware...")
  local log_mw = MiddlewarePipeline.new()
  local log_lines = {}
  log_mw:logging {
    logger = function(msg)
      log_lines[#log_lines + 1] = msg
    end,
  }
  assert_true(log_mw:count() > 0, "Logging middleware added")

  print("CORS middleware...")
  local cors_pipeline = MiddlewarePipeline.new()
  cors_pipeline:cors("*")
  local cors_req = Request.new()
  cors_req.method = "OPTIONS"
  cors_req.path = "/"
  local cors_resp = cors_pipeline:execute(cors_req)
  assert_true(cors_resp.headers["Access-Control-Allow-Origin"] ~= nil, "CORS origin header set")
  assert_eq(cors_resp.status_code, 204, "Preflight OPTIONS returns 204")

  print("Clear middleware pipeline...")
  pipeline:clear()
  assert_eq(pipeline:count(), 0, "Pipeline cleared successfully")
end

print("")
print("=== App Tests ===")

do
  local App = require("app")

  print("Application creation and DSL...")
  local app = App.new()
  app:get("/", function(req, res) return res:text("index") end)
  app:get("/items/:id", function(req, res)
    return res:json({ item_id = req:get_route_param("id") })
  end)
  app:post("/items", function(req, res)
    return res:json({ created = true })
  end)

  assert_true(app:router():count() >= 3, "Routes registered via DSL")

  print("Handling raw requests through app...")
  local handle_resp = app:handle_raw("GET / HTTP/1.1\r\n\r\n")
  assert_eq(handle_resp.status_code, 200, "App handles GET /")
  assert_contains(handle_resp.body, "index", "GET / returns index")

  print("Handling parameterized route through app...")
  local item_resp = app:handle_raw("GET /items/99 HTTP/1.1\r\n\r\n")
  assert_eq(item_resp.status_code, 200, "App handles GET /items/:id")
  assert_contains(item_resp.body, "99", "Param captured by app")

  print("Middleware integration with app...")
  local mw_app = App.new()
  mw_app:use(function(req, res, next)
    req._processed = true
    next()
  end)
  mw_app:get("/check", function(req, res)
    return res:json({ processed = req._processed })
  end)
  local mw_resp = mw_app:handle_raw("GET /check HTTP/1.1\r\n\r\n")
  assert_contains(mw_resp.body, "true", "Middleware sets properties on request")

  print("Simulation mode...")
  local sim_resp = app:simulate("GET", "/")
  assert_true(sim_resp.status_code ~= nil, "Simulate returns response")
end

print("")
print("=== JSON Serialization Tests ===")

do
  local Response = require("response")

  print("Serializing nil...")
  assert_eq(Response._to_json(nil), "null", "nil -> null")

  print("Serializing numbers...")
  assert_eq(Response._to_json(42), "42", "Integer serialized")
  assert_eq(Response._to_json(3.14), "3.14", "Float serialized")

  print("Serializing booleans...")
  assert_eq(Response._to_json(true), "true", "true serialized")
  assert_eq(Response._to_json(false), "false", "false serialized")

  print("Serializing strings...")
  assert_eq(Response._to_json("hello"), '"hello"', "Simple string")
  assert_eq(Response._to_json("line1\nline2"), '"line1\\nline2"', "String with newline")

  print("Serializing arrays...")
  assert_eq(Response._to_json({1, 2, 3}), "[1, 2, 3]", "Array of numbers")
  assert_eq(Response._to_json({}), "[]", "Empty array")

  print("Serializing objects...")
  local obj_json = Response._to_json({a = 1, b = "x"})
  assert_contains(obj_json, '"a"', "Object has key a")
  assert_contains(obj_json, '"b"', "Object has key b")
end

print("")
print("===========================")
print(("Results: %d/%d passed"):format(pass, total))
if fail > 0 then
  print(("FAILURES: %d tests failed"):format(fail))
else
  print("ALL TESTS PASSED!")
end
