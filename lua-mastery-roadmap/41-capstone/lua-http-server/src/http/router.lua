-- router.lua — Method-based and parameterized URL routing.
-- Matches incoming requests against registered routes and dispatches
-- to the appropriate handler. Supports path parameters via :param syntax.

local Request = require("request")
local Response = require("response")

local Router = {}
Router.__index = Router

--- Create a new Router.
function Router.new()
  return setmetatable({
    routes = {},         -- ordered list of registered routes
    middleware_chain = {}, -- per-route middleware
    error_handlers = {},  -- method -> handler mappings
  }, Router)
end

--- Register a route for a specific HTTP method.
function Router:add_route(method, pattern, handler)
  self.routes[#self.routes + 1] = {
    method = method:upper(),
    pattern = pattern,
    handler = handler,
  }
  return self
end

--- Convenience: GET route.
function Router:get(pattern, handler)
  return self:add_route("GET", pattern, handler)
end

--- Convenience: POST route.
function Router:post(pattern, handler)
  return self:add_route("POST", pattern, handler)
end

--- Convenience: PUT route.
function Router:put(pattern, handler)
  return self:add_route("PUT", pattern, handler)
end

--- Convenience: DELETE route.
function Router:delete(pattern, handler)
  return self:add_route("DELETE", pattern, handler)
end

--- Convenience: PATCH route.
function Router:patch(pattern, handler)
  return self:add_route("PATCH", pattern, handler)
end

--- Register middleware that runs before route matching.
function Router:use(middleware)
  self.middleware_chain[#self.middleware_chain + 1] = middleware
  return self
end

--- Route a request to the matching handler.
-- Returns (response, matched_route_info) or (error_response, nil).
function Router:route(request)
  -- Run global middleware chain first
  for _, mw in ipairs(self.middleware_chain) do
    local ok, result = pcall(mw, request)
    if not ok then
      -- Middleware failed — treat as 500
      return Response.internal_error("Middleware error: " .. tostring(result))
    end
    -- Middleware can short-circuit by returning a response directly
    if result and result.status_code then
      return result
    end
  end

  -- Find matching route
  local route, params = self:_find_match(request.method, request.path)
  if not route then
    return Response.not_found("Route not found: " .. request.method .. " " .. request.path)
  end

  -- Attach matched params to request
  request.params = params

  -- Create a default response for the handler
  local response = Response.new(200, "")

  -- Call handler
  local ok, result = pcall(route.handler, request, response)
  if not ok then
    return Response.internal_error("Handler error: " .. tostring(result))
  end

  -- Handler can return a string (auto-wrapped), nil (204), or Response object
  -- If handler returns nothing, use the response built during handler execution
  if type(result) == "string" then
    return Response.ok(result)
  elseif result == nil then
    -- Check if handler modified the response object
    if response.body and #response.body > 0 then
      return response
    end
    local resp2 = Response.ok("")
    resp2.headers["Content-Length"] = "0"
    resp2.status_code = 204
    return resp2
  elseif type(result) == "table" and getmetatable(result) and result.status_code then
    return result
  end

  return Response.ok(tostring(result or ""))
end

--- Match a request against routes.
-- Returns (route_table, params_table) or (nil, nil).
function Router:_find_match(method, path)
  for _, route in ipairs(self.routes) do
    if route.method ~= method then
      goto continue
    end

    -- Exact match
    if route.pattern == path then
      return route, {}
    end

    -- Parameterized match: /users/:id -> capture id
    local matched, params = self:_match_pattern(route.pattern, path)
    if matched then
      return route, params
    end

    ::continue::
  end
  return nil, nil
end

--- Match a pattern like "/users/:id/posts/:post_id" against a path.
function Router:_match_pattern(pattern, path)
  local pattern_parts = {}
  for part in pattern:gmatch("[^/]+") do
    pattern_parts[#pattern_parts + 1] = part
  end

  local path_parts = {}
  for part in path:gmatch("[^/]+") do
    path_parts[#path_parts + 1] = part
  end

  if #pattern_parts ~= #path_parts then
    return nil
  end

  local params = {}
  for i = 1, #pattern_parts do
    local pp = pattern_parts[i]
    local pathp = path_parts[i]
    if pp:sub(1, 1) == ":" then
      params[pp:sub(2)] = pathp
    elseif pp ~= pathp then
      return nil
    end
  end

  return true, params
end

--- Get total number of registered routes.
function Router:count()
  return #self.routes
end

--- Return human-readable route listing.
function Router:list_routes()
  local lines = {}
  lines[1] = "Registered Routes:"
  for i, route in ipairs(self.routes) do
    lines[i + 1] = ("  %s %-8s %s"):format(i, route.method, route.pattern)
  end
  return table.concat(lines, "\n")
end

return Router
