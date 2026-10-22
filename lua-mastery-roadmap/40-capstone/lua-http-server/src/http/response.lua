-- response.lua — HTTP Response builder with fluent API.
-- Provides methods for setting status codes, headers, and body content
-- in various formats (text, JSON, HTML).

local Response = {}
Response.__index = Response

--- Status text lookup table (defined before _status_text call).
local status_texts = {
  [200] = "OK",
  [201] = "Created",
  [204] = "No Content",
  [301] = "Moved Permanently",
  [302] = "Found",
  [304] = "Not Modified",
  [400] = "Bad Request",
  [401] = "Unauthorized",
  [403] = "Forbidden",
  [404] = "Not Found",
  [405] = "Method Not Allowed",
  [409] = "Conflict",
  [500] = "Internal Server Error",
  [502] = "Bad Gateway",
  [503] = "Service Unavailable",
}

--- Get status text for a given code.
local function get_status_text(code)
  return status_texts[code] or "Unknown"
end

--- Create a new Response.
function Response.new(status, body)
  return setmetatable({
    status_code = status or 200,
    status_text = get_status_text(status or 200),
    headers = {
      ["Content-Type"] = "text/plain; charset=utf-8",
    },
    body = body or "",
  }, Response)
end

--- Convenience constructors.
function Response.ok(body)
  return Response.new(200, body or "")
end

function Response.not_found(body)
  return Response.new(404, body or "Not Found")
end

function Response.bad_request(body)
  return Response.new(400, body or "Bad Request")
end

function Response.internal_error(body)
  return Response.new(500, body or "Internal Server Error")
end

function Response.created(body)
  return Response.new(201, body or "")
end

--- Set a header.
function Response:set_header(name, value)
  self.headers[name] = value
  return self
end

--- Set the body content.
function Response:set_body(body)
  self.body = body or ""
  self.headers["Content-Length"] = tostring(#self.body)
  return self
end

--- Respond with plain text.
function Response:text(text)
  self.headers["Content-Type"] = "text/plain; charset=utf-8"
  self.status_code = 200
  self.status_text = "OK"
  self.body = text or ""
  self.headers["Content-Length"] = tostring(#self.body)
  return self
end

--- Respond with JSON.
function Response:json(data)
  self.body = Response._to_json(data)
  self.headers["Content-Type"] = "application/json; charset=utf-8"
  self.status_code = 200
  self.status_text = "OK"
  self.headers["Content-Length"] = tostring(#self.body)
  return self
end

--- Respond with HTML.
function Response:html(html)
  self.headers["Content-Type"] = "text/html; charset=utf-8"
  self.status_code = 200
  self.status_text = "OK"
  self.body = html or ""
  self.headers["Content-Length"] = tostring(#self.body)
  return self
end

--- Set redirect response.
function Response:redirect(location)
  self.status_code = 302
  self.status_text = "Found"
  self.body = ""
  self.headers["Location"] = location
  self.headers["Content-Length"] = "0"
  return self
end

--- Serialize Lua table to JSON string.
-- Works across all Lua versions without external dependencies.
function Response._to_json(data)
  if data == nil then
    return "null"
  elseif type(data) == "number" then
    return tostring(data)
  elseif type(data) == "boolean" then
    return data and "true" or "false"
  elseif type(data) == "string" then
    return Response._escape_json_string(data)
  elseif type(data) == "table" then
    return Response._table_to_json(data)
  else
    return "null"
  end
end

function Response._escape_json_string(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  return '"' .. s .. '"'
end

function Response._table_to_json(t)
  -- Check if array-like (integer keys starting from 1)
  local is_array = true
  local count = 0
  for k, _ in pairs(t) do
    count = count + 1
    if type(k) ~= "number" or k < 1 then
      is_array = false
      break
    end
  end

  if is_array and count > 0 then
    local parts = {}
    for i = 1, count do
      parts[i] = Response._to_json(t[i])
    end
    return "[" .. table.concat(parts, ", ") .. "]"
  elseif is_array and count == 0 then
    return "[]"
  else
    local parts = {}
    for k, v in pairs(t) do
      parts[#parts + 1] = Response._escape_json_string(tostring(k))
            .. ": " .. Response._to_json(v)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  end
end

--- Return string representation of this response (for sending over TCP).
function Response:__tostring()
  local lines = {}
  lines[1] = "HTTP/1.1 " .. self.status_code .. " " .. self.status_text
  for name, value in pairs(self.headers) do
    lines[#lines + 1] = name .. ": " .. value
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = self.body
  return table.concat(lines, "\r\n")
end

--- Get current status code.
function Response:get_status_code()
  return self.status_code
end

return Response
