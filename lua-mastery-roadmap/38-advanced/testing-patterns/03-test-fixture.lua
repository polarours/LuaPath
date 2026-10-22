#!/usr/bin/env lua
-- Stage 38: Testing Patterns - Test Fixture
-- Reusable test setup and teardown
-- Lua Version: 5.1+
--
-- Demonstrates: paired setup/teardown, teardown on the error path, nested fixtures, resource accounting

-- ---------------------------------------------------------------------------
-- A resource that has to be released
-- ---------------------------------------------------------------------------

--- Create a pool of connections.
-- `open` counts the connections currently held out. A fixture that forgets
-- its teardown leaves that number above zero, and that number is what the
-- checks below watch.
-- @param name the pool name
-- @return table the pool
local function new_pool(name)
  return { name = name, open = 0, acquired = 0, released = 0 }
end

--- Take a connection out of the pool.
-- @param pool the pool
-- @return table the connection handle
local function acquire(pool)
  pool.acquired = pool.acquired + 1
  pool.open = pool.open + 1
  return { id = pool.acquired, pool = pool, released = false }
end

--- Give a connection back to the pool.
-- Releasing twice is a no-op, so a teardown that runs twice cannot corrupt
-- the count.
-- @param pool the pool
-- @param connection the handle returned by `acquire`
-- @return boolean true if this call performed the release
local function release(pool, connection)
  if connection.released then
    return false
  end
  connection.released = true
  pool.open = pool.open - 1
  pool.released = pool.released + 1
  return true
end

-- ---------------------------------------------------------------------------
-- The fixture
-- ---------------------------------------------------------------------------

--- Run a test body with a fixture and release the fixture afterwards.
-- Setup and teardown are a pair: the release happens on the success path and
-- on the error path, so a failing test cannot leak the resource. The error
-- handler normalises whatever was raised into a string, so the report reads
-- the same on every supported Lua version.
-- @param setup function() that allocates the resource
-- @param teardown function(resource) that releases it
-- @param body function(resource) the test body
-- @return table result with `ok`, `error` and `teardown_error`
local function with_fixture(setup, teardown, body)
  local resource = setup()
  local ok, err = xpcall(function()
    return body(resource)
  end, function(message)
    return tostring(message)
  end)
  -- The teardown is paired with the setup and runs whatever happened above.
  local teardown_ok, teardown_err = pcall(teardown, resource)
  -- The fields are set one at a time on purpose: `ok and nil or err` cannot
  -- express "no error", because a nil on the left of `or` always falls
  -- through to the right.
  local result = { ok = ok }
  if not ok then
    result.error = err
  end
  if not teardown_ok then
    result.teardown_error = tostring(teardown_err)
  end
  return result
end

--- Run a body inside a transaction opened on a connection.
-- The transaction is closed on both paths as well: it commits when the body
-- succeeds and rolls back when it fails.
-- @param connection the connection handle
-- @param body function(connection) the test body
-- @return table result with `ok`, `error` and `state`
local function with_transaction(connection, body)
  connection.transactions = (connection.transactions or 0) + 1
  connection.state = "open"
  local ok, err = xpcall(function()
    return body(connection)
  end, function(message)
    return tostring(message)
  end)
  connection.state = ok and "committed" or "rolled back"
  local result = { ok = ok, state = connection.state }
  if not ok then
    result.error = err
  end
  return result
end

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

local pool = new_pool("test-db")

-- A passing test: the fixture hands a connection over and takes it back.
local pass = with_fixture(
  function()
    return acquire(pool)
  end,
  function(connection)
    release(pool, connection)
  end,
  function(connection)
    assert(connection.id == 1)
    assert(connection.released == false)
    assert(pool.open == 1)
  end)

assert(pass.ok == true)
assert(pass.error == nil)
assert(pass.teardown_error == nil)
assert(pool.open == 0)
assert(pool.released == 1)

-- A failing test: the body raises, but the teardown still runs, so the
-- connection does not leak.
local fail = with_fixture(
  function()
    return acquire(pool)
  end,
  function(connection)
    release(pool, connection)
  end,
  function()
    error("the assertion failed", 0)
  end)

assert(fail.ok == false)
assert(fail.error:find("the assertion failed", 1, true) ~= nil)
assert(fail.teardown_error == nil)
assert(pool.open == 0)
assert(pool.released == 2)

-- Nested fixtures: the inner one closes before the outer one releases.
local order = {}
local nested = with_fixture(
  function()
    return acquire(pool)
  end,
  function(connection)
    order[#order + 1] = "connection released"
    release(pool, connection)
  end,
  function(connection)
    order[#order + 1] = "connection acquired"
    local inner = with_transaction(connection, function()
      order[#order + 1] = "transaction body"
      assert(connection.state == "open")
    end)
    assert(inner.ok == true)
    assert(inner.state == "committed")
    order[#order + 1] = "transaction closed"
  end)

assert(nested.ok == true)
assert(order[1] == "connection acquired")
assert(order[2] == "transaction body")
assert(order[3] == "transaction closed")
assert(order[4] == "connection released")
assert(pool.open == 0)
assert(pool.released == 3)

-- A failure inside the nested fixture unwinds both fixtures: the inner
-- transaction rolls back and the outer connection is still released.
local nested_fail = with_fixture(
  function()
    return acquire(pool)
  end,
  function(connection)
    release(pool, connection)
  end,
  function(connection)
    local inner = with_transaction(connection, function()
      error("the inner assertion failed", 0)
    end)
    assert(inner.ok == false)
    assert(inner.state == "rolled back")
    assert(inner.error:find("the inner assertion failed", 1, true) ~= nil)
    -- The inner fixture has closed; the outer one still owns the connection.
    assert(connection.state == "rolled back")
    assert(pool.open == 1)
    error("the outer assertion failed", 0)
  end)

assert(nested_fail.ok == false)
assert(nested_fail.error:find("the outer assertion failed", 1, true) ~= nil)
assert(nested_fail.teardown_error == nil)
assert(pool.open == 0)
assert(pool.released == 4)

-- A teardown that raises is reported, but it does not mask the test result
-- and it does not skip the release that came before it.
local bad_teardown = with_fixture(
  function()
    return acquire(pool)
  end,
  function(connection)
    release(pool, connection)
    error("teardown exploded", 0)
  end,
  function()
    error("the test failed too", 0)
  end)

assert(bad_teardown.ok == false)
assert(bad_teardown.error:find("the test failed too", 1, true) ~= nil)
assert(bad_teardown.teardown_error:find("teardown exploded", 1, true) ~= nil)
assert(pool.open == 0)

-- Every acquire was matched by exactly one release: no fixture leaked.
assert(pool.acquired == pool.released)
assert(pool.released == 5)
assert(pool.open == 0)

print("✓ test-fixture tests passed")
