#!/usr/bin/env lua
-- Stage 37: Error Patterns - Error Codes
-- Enum-based error reporting with messages
-- Lua Version: 5.1+
--
-- Demonstrates: enum tables, structured error returns, message formatting

--- The catalogue of error codes this module can report.
-- Codes are plain strings so they survive serialisation and compare with
-- `==`; the module never invents a code on the fly.
local Code = {
  NOT_FOUND = "NOT_FOUND",
  INVALID_ARGUMENT = "INVALID_ARGUMENT",
  OUT_OF_RANGE = "OUT_OF_RANGE",
  ALREADY_EXISTS = "ALREADY_EXISTS",
}

--- Every code the module knows about, in a stable order.
local CODE_LIST = {
  Code.NOT_FOUND,
  Code.INVALID_ARGUMENT,
  Code.OUT_OF_RANGE,
  Code.ALREADY_EXISTS,
}

--- Build a structured error value.
-- @param code one of the Code constants
-- @param message a human readable description
-- @param details optional table of extra fields
-- @return table the error value
local function make_error(code, message, details)
  if not Code[code] then
    error("unknown error code: " .. tostring(code))
  end
  return {
    code = code,
    message = message,
    details = details or {},
  }
end

--- Render an error as a single line for a log.
-- @param err the error value
-- @return string
local function format_error(err)
  local parts = { "[" .. err.code .. "] " .. err.message }
  local keys = {}
  for key in pairs(err.details) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    parts[#parts + 1] = key .. "=" .. tostring(err.details[key])
  end
  return table.concat(parts, " ")
end

--- Look a user up in a small directory.
-- @param users table mapping id to record
-- @param id the id to look for
-- @return table|nil the record, or nil plus an error value
local function find_user(users, id)
  local record = users[id]
  if not record then
    return nil, make_error(Code.NOT_FOUND, "no such user", { id = id })
  end
  if type(record.age) ~= "number" then
    return nil, make_error(Code.INVALID_ARGUMENT, "user has no numeric age", { id = id })
  end
  if record.age < 0 or record.age > 150 then
    return nil, make_error(Code.OUT_OF_RANGE, "age is out of range", {
      id = id,
      age = record.age,
    })
  end
  return record
end

--- Register a user, refusing duplicates.
-- @param users the directory table
-- @param id the new id
-- @param record the record to store
-- @return boolean ok, or nil plus an error value
local function add_user(users, id, record)
  if users[id] then
    return nil, make_error(Code.ALREADY_EXISTS, "user already exists", { id = id })
  end
  users[id] = record
  return true
end

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

local users = {
  alice = { name = "Alice", age = 30 },
  bob = { name = "Bob", age = 41 },
  ghost = { name = "Ghost", age = 900 },
  nameless = { name = "Nameless" },
}

local record, err = find_user(users, "alice")
assert(record and record.name == "Alice")
assert(err == nil)

record, err = find_user(users, "carol")
assert(record == nil)
assert(err.code == Code.NOT_FOUND)
assert(err.details.id == "carol")
assert(format_error(err) == "[NOT_FOUND] no such user id=carol")

record, err = find_user(users, "ghost")
assert(record == nil)
assert(err.code == Code.OUT_OF_RANGE)
assert(err.details.age == 900)
assert(format_error(err) == "[OUT_OF_RANGE] age is out of range age=900 id=ghost")

record, err = find_user(users, "nameless")
assert(record == nil)
assert(err.code == Code.INVALID_ARGUMENT)

assert(add_user(users, "carol", { name = "Carol", age = 25 }))
assert(users.carol.name == "Carol")

local ok, dup_err = add_user(users, "carol", { name = "Again", age = 1 })
assert(ok == nil)
assert(dup_err.code == Code.ALREADY_EXISTS)

-- The code catalogue is closed: an unknown code is a programming error.
assert(pcall(make_error, "MADE_UP", "nope") == false)
assert(#CODE_LIST == 4)

print("✓ error-codes tests passed")
