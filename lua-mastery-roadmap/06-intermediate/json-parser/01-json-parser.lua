--[[
  Example: JSON Parser
  Chapter: Stage 6 — Intermediate
  Difficulty: Intermediate
  Lua Version: 5.1+
  Demonstrates: Recursive descent parsing, lexer/tokenizer, grammar-driven design
]]

local json = {}

local function tokenize(str)
  local pos, tokens = 1, {}
  local function peek() return str:sub(pos, pos) end
  local function advance() pos = pos + 1 end
  local function skip_ws()
    while pos <= #str and peek():match("[ \t\n\r]") do advance() end
  end
  local function read_string()
    advance()
    local start = pos
    local parts = {}
    while pos <= #str do
      local c = peek()
      if c == '"' then advance(); return table.concat(parts) .. str:sub(start, pos - 2)
      elseif c == '\\' then
        parts[#parts + 1] = str:sub(start, pos - 1)
        advance(); local esc = peek()
        local map = { n = '\n', t = '\t', r = '\r' }
        parts[#parts + 1] = map[esc] or esc
        advance(); start = pos
      else advance() end
    end
    error("Unterminated string")
  end
  local function read_number()
    local s = pos
    if peek() == '-' then advance() end
    while pos <= #str and peek():match('[%d%.eE%+%-]') do advance() end
    return tonumber(str:sub(s, pos - 1))
  end
  while pos <= #str do
    skip_ws(); if pos > #str then break end
    local c = peek()
    if c == '"' then tokens[#tokens + 1] = { type = "string", value = read_string() }
    elseif c == '{' or c == '}' or c == '[' or c == ']' or c == ':' or c == ',' then
      tokens[#tokens + 1] = { type = c }; advance()
    elseif c == 't' then tokens[#tokens + 1] = { type = "boolean", value = true }; pos = pos + 4
    elseif c == 'f' then tokens[#tokens + 1] = { type = "boolean", value = false }; pos = pos + 5
    elseif c == 'n' then tokens[#tokens + 1] = { type = "null" }; pos = pos + 4
    elseif c:match('[%d%-]') then tokens[#tokens + 1] = { type = "number", value = read_number() }
    else error("Unexpected char: " .. c .. " at " .. pos) end
  end
  return tokens
end

local function parse_tokens(tokens)
  local pos = 1
  local function peek() return tokens[pos] end
  local function advance() pos = pos + 1 end
  local function parse_value()
    local t = peek().type
    if t == "string" or t == "number" or t == "boolean" then
      local v = peek().value; advance(); return v
    elseif t == "null" then advance(); return nil
    elseif t == "{" then return parse_object()
    elseif t == "[" then return parse_array()
    else error("Unexpected: " .. t) end
  end
  function parse_object()
    advance(); local obj = {}
    if peek().type == "}" then advance(); return obj end
    while true do
      local key = parse_value(); advance()
      obj[key] = parse_value()
      if peek().type == "," then advance() else advance(); break end
    end
    return obj
  end
  function parse_array()
    advance(); local arr = {}
    if peek().type == "]" then advance(); return arr end
    while true do
      arr[#arr + 1] = parse_value()
      if peek().type == "," then advance() else advance(); break end
    end
    return arr
  end
  return parse_value()
end

function json.decode(str) return parse_tokens(tokenize(str)) end

-- Test cases
local tests = {
  { 'null', nil }, { 'true', true }, { 'false', false },
  { '42', 42 }, { '3.14', 3.14 }, { '"hello"', "hello" },
  { '"a\\"b"', 'a"b' }, { '{}', {} }, { '[]', {} },
  { '[1,2,3]', {1, 2, 3} },
  { '{"x":1,"y":[2,3],"z":{"nested":true}}',
    { x = 1, y = {2, 3}, z = { nested = true } } },
}

local passed, failed = 0, 0
for i, t in ipairs(tests) do
  local ok, result = pcall(json.decode, t[1])
  if not ok then print("[FAIL] " .. i .. ": " .. t[1] .. " — " .. result); failed = failed + 1
  else print("[PASS] " .. i .. ": " .. t[1]); passed = passed + 1 end
end
print(string.format("\nResults: %d passed, %d failed", passed, failed))

return json
