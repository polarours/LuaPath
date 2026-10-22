-- request.lua — HTTP Request parser and representation
-- Uses metatables to create a method-based API for accessing parsed data.

local Request = {}
Request.__index = Request

--- Create a new empty Request.
function Request.new()
  return setmetatable({
    method = "GET",
    path = "/",
    version = "HTTP/1.1",
    headers = {},
    query_string = "",
    query_params = {},
    params = {},
    body = "",
  }, Request)
end

--- Split string by CRLF or LF.
local function split_lines(s)
  -- Normalize CRLF to LF first
  s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
  local lines = {}
  local start = 1
  while true do
    local nl = s:find("\n", start, true)
    if not nl then
      -- Last line (no trailing newline)
      if start <= #s then
        lines[#lines + 1] = s:sub(start)
      end
      break
    end
    lines[#lines + 1] = s:sub(start, nl - 1)
    start = nl + 1
  end
  return lines
end

--- Parse raw HTTP request text into a Request object.
-- Handles request line, headers, blank-line separator, and optional body.
function Request.parse(raw)
  local req = Request.new()
  local lines = split_lines(raw)

  if #lines < 1 then
    return req
  end

  -- First line: "GET /path HTTP/1.1"
  req:_parse_first_line(lines[1])

  -- Lines 2..N are headers (until empty line)
  local body_start = #lines + 1
  for i = 2, #lines do
    if lines[i] == "" then
      body_start = i + 1
      break
    end
    local key, val = lines[i]:match("^([^:]+)[%s]*:%s*(.*)")
    if key then
      req.headers[key] = val
    end
  end

  -- Body is everything after the blank line
  if body_start <= #lines then
    req.body = table.concat(lines, "\n", body_start)
  end

  -- Parse query string from path
  local path_and_query = req.path
  local query_idx = path_and_query:find("?")
  if query_idx then
    req.query_string = path_and_query:sub(query_idx + 1)
    req.path = path_and_query:sub(1, query_idx - 1)
    req:_parse_query_string(req.query_string)
  end

  req:_set_content_length()

  return req
end

--- Internal: parse a single request line into method/path/version.
function Request:_parse_first_line(line)
  local method, path, version = line:match("^(%S+)%s+(%S+)(.*)$")
  if method then
    self.method = method
    self.path = path
  end
  if version then
    self.version = (version or ""):match("^%s+(%S+)")
  end
end

--- Internal: parse query parameters from query_string.
function Request:_parse_query_string(qs)
  for param in qs:gmatch("[^&]+") do
    local eq = param:find("=")
    if eq then
      self.query_params[param:sub(1, eq - 1)] = param:sub(eq + 1)
    else
      self.query_params[param] = ""
    end
  end
end

--- Internal: set default Content-Length if body exists.
function Request:_set_content_length()
  if #self.body > 0 and not self.headers["Content-Length"] then
    self.headers["Content-Length"] = tostring(#self.body)
  end
end

--- Get a header value by name, case-insensitive.
function Request:get_header(name)
  local lname = name:lower()
  for k, v in pairs(self.headers) do
    if k:lower() == lname then
      return v
    end
  end
  return nil
end

--- Get a query parameter by name.
function Request:get_param(name)
  return self.query_params[name]
end

--- Get a route parameter (path segment like :id).
function Request:get_route_param(name)
  return self.params[name]
end

--- Check if the request has a given header.
function Request:has_header(name)
  return self:get_header(name) ~= nil
end

return Request
