#!/usr/bin/env lua
-- Stage 37: Error Patterns - Expected Pattern
-- Value-or-error with monadic operations
-- Lua Version: 5.1+
--
-- Demonstrates: expected values, value-or-error returns, monadic bind, failure recovery, short-circuiting fallback

--- An expectation: a value that is either a success carrying a value, or a
-- failure carrying a reason. The rule of the pattern is that a function hands
-- back EITHER a plain value OR an expectation -- never a raised error -- so
-- the caller is forced to look at the failure instead of catching it.
local Expected = {}
Expected.__index = Expected

--- Wrap a value as a successful expectation.
-- @param value the value to carry
-- @return table the expectation
function Expected.ok(value)
  return setmetatable({ success = true, value = value }, Expected)
end

--- Wrap a failure reason as a failed expectation.
-- @param reason why the operation failed
-- @return table the expectation
function Expected.err(reason)
  return setmetatable({ success = false, reason = reason }, Expected)
end

--- Report whether the expectation succeeded.
-- @return boolean true when it carries a value
function Expected:is_ok()
  return self.success
end

--- Report whether the expectation failed.
-- @return boolean true when it carries a reason
function Expected:is_err()
  return not self.success
end

--- Map a function over a successful value. A failure is propagated unchanged.
-- @param fn the function applied to the carried value
-- @return table the expectation
function Expected:map(fn)
  if not self.success then
    return self
  end
  return Expected.ok(fn(self.value))
end

--- Continue the chain with a function that itself returns an expectation.
-- A failure short-circuits the chain and is propagated unchanged.
-- @param fn the function applied to the carried value; it returns an expectation
-- @return table the expectation
function Expected:bind(fn)
  if not self.success then
    return self
  end
  return fn(self.value)
end

--- Recover from a failure with a function that returns a new expectation.
-- A success is propagated unchanged.
-- @param fn the function applied to the failure reason; it returns an expectation
-- @return table the expectation
function Expected:or_else(fn)
  if self.success then
    return self
  end
  return fn(self.reason)
end

--- Short-circuit to a default when the expectation failed.
-- @param default the value to use instead of a failure
-- @return any the carried value, or the default
function Expected:unwrap_or(default)
  if self.success then
    return self.value
  end
  return default
end

--- Take the carried value, or raise. The deliberate escape hatch out of the
-- pattern, for the rare place where a failure really is a programming error.
-- @return any the carried value
function Expected:unwrap()
  if self.success then
    return self.value
  end
  error("unwrap() on a failed expectation: " .. tostring(self.reason), 2)
end

-- ---------------------------------------------------------------------------
-- The value-or-error contract
-- ---------------------------------------------------------------------------

--- Turn an expectation into the "plain value or expectation" pair.
-- The second return is nil exactly when the first one is a real value, so a
-- caller that ignores it silently drops a failure.
-- @param expectation the expectation to unwrap
-- @return any value, table|nil expectation
local function value_or_error(expectation)
  if expectation:is_ok() then
    return expectation.value, nil
  end
  return nil, expectation
end

--- Read one entry of a parsed configuration.
-- @param entries the entries, each an expectation
-- @param name the entry to read
-- @return any value, table|nil expectation
local function read_entry(entries, name)
  local entry = entries[name]
  if entry == nil then
    return nil, Expected.err("no such entry: " .. name)
  end
  return value_or_error(entry)
end

-- ---------------------------------------------------------------------------
-- A small domain: reading a server configuration
-- ---------------------------------------------------------------------------

--- Parse a decimal integer.
-- @param text the text to parse
-- @return table the expectation
local function parse_int(text)
  if type(text) ~= "string" then
    return Expected.err("not a number: " .. tostring(text))
  end
  local number = tonumber(text)
  if not number or number % 1 ~= 0 then
    return Expected.err("not an integer: " .. text)
  end
  return Expected.ok(number)
end

--- Parse a TCP port.
-- @param text the text to parse
-- @return table the expectation
local function parse_port(text)
  return parse_int(text):bind(function(number)
    if number < 1 or number > 65535 then
      return Expected.err("port out of range: " .. tostring(text))
    end
    return Expected.ok(number)
  end)
end

--- Parse a boolean flag.
-- @param text the text to parse
-- @return table the expectation
local function parse_flag(text)
  if type(text) ~= "string" then
    return Expected.err("not a boolean: " .. tostring(text))
  end
  local lowered = string.lower(text)
  if lowered == "true" or lowered == "yes" or lowered == "1" then
    return Expected.ok(true)
  end
  if lowered == "false" or lowered == "no" or lowered == "0" then
    return Expected.ok(false)
  end
  return Expected.err("not a boolean: " .. text)
end

--- Build the server configuration from raw text fields.
-- Every step of the chain only runs when the previous one succeeded, so the
-- first failure decides the outcome and the rest of the fields are never
-- looked at.
-- @param raw the raw fields
-- @return table the expectation
local function build_config(raw)
  return Expected.ok({})
    :bind(function(config)
      return parse_port(raw.port):map(function(port)
        config.port = port
        return config
      end)
    end)
    :bind(function(config)
      return parse_int(raw.retries):map(function(retries)
        config.retries = retries
        return config
      end)
    end)
    :bind(function(config)
      return parse_flag(raw.enabled):map(function(enabled)
        config.enabled = enabled
        return config
      end)
    end)
end

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

-- Returning a value: a success carries the value, a failure carries a reason.
local success = Expected.ok(42)
local failure = Expected.err("boom")
assert(success:is_ok())
assert(not success:is_err())
assert(success.value == 42)
assert(success:unwrap() == 42)
assert(failure:is_err())
assert(failure.reason == "boom")

-- A carried value may be false: the `success` flag is the discriminator, so
-- a false value is never mistaken for a failure.
local flag = Expected.ok(false)
assert(flag:is_ok())
assert(flag:unwrap_or("default") == false)

-- Chaining: a success is mapped over, a failure propagates unchanged.
assert(success:map(function(value) return value * 2 end).value == 84)
assert(failure:map(function(value) return value * 2 end) == failure)
assert(failure:map(function(value) return value * 2 end).reason == "boom")

-- Binding a success: the next step receives the value and returns a new
-- expectation of its own.
assert(success:bind(function(value) return Expected.ok(value + 1) end).value == 43)
assert(failure:bind(function(value) return Expected.ok(value + 1) end) == failure)

-- Binding a failure: the recovery decides what happens next, and a success
-- is left alone.
local recovered = failure:or_else(function(reason)
  return Expected.ok("recovered from " .. reason)
end)
assert(recovered.value == "recovered from boom")
assert(success:or_else(function() return Expected.err("unused") end) == success)
assert(failure:or_else(function(reason) return Expected.err("wrapped: " .. reason) end).reason == "wrapped: boom")

-- The short-circuiting fallback: no reason to handle the failure at all.
assert(Expected.err("nope"):unwrap_or("fallback") == "fallback")
assert(Expected.ok("kept"):unwrap_or("fallback") == "kept")

-- The whole chain succeeds on a well formed configuration.
local config = build_config({ port = "8080", retries = "3", enabled = "yes" })
assert(config:is_ok())
assert(config.value.port == 8080)
assert(config.value.retries == 3)
assert(config.value.enabled == true)

-- A failure in the middle stops the chain and keeps its own reason.
local bad_port = build_config({ port = "70000", retries = "3", enabled = "yes" })
assert(bad_port:is_err())
assert(bad_port.reason == "port out of range: 70000")

local bad_retries = build_config({ port = "8080", retries = "many", enabled = "yes" })
assert(bad_retries:is_err())
assert(bad_retries.reason == "not an integer: many")

local missing_port = build_config({ retries = "3", enabled = "yes" })
assert(missing_port:is_err())
assert(missing_port.reason == "not a number: nil")

-- Recovering from a failed chain: the recovery may return a whole config.
local fixed = bad_port:or_else(function(reason)
  if reason == "port out of range: 70000" then
    return Expected.ok({ port = 8080, retries = 3, enabled = true })
  end
  return Expected.err(reason)
end)
assert(fixed:is_ok())
assert(fixed.value.port == 8080)

-- Recovering one field only, leaving the rest of the chain intact.
local port = parse_port("70000"):or_else(function()
  return Expected.ok(8080)
end)
assert(port:is_ok())
assert(port.value == 8080)

-- The value-or-error contract: the caller gets the value, or the expectation
-- that says why there is no value.
local value, expectation = value_or_error(parse_port("8080"))
assert(value == 8080)
assert(expectation == nil)

value, expectation = value_or_error(parse_port("70000"))
assert(value == nil)
assert(expectation:is_err())
assert(expectation.reason == "port out of range: 70000")

-- Reading a named entry reports a missing one instead of returning nil.
local entries = {
  port = parse_port("8080"),
  retries = parse_int("3"),
}
value, expectation = read_entry(entries, "port")
assert(value == 8080)
assert(expectation == nil)

value, expectation = read_entry(entries, "retries")
assert(value == 3)
assert(expectation == nil)

value, expectation = read_entry(entries, "missing")
assert(value == nil)
assert(expectation:is_err())
assert(expectation.reason == "no such entry: missing")

-- The escape hatch raises, which is exactly what the pattern is avoiding.
assert(pcall(function() return failure:unwrap() end) == false)

print("✓ expected-pattern tests passed")
