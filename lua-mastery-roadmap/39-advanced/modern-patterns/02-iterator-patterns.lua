#!/usr/bin/env lua
-- Stage 39: Modern Patterns - Iterator Patterns
-- Parallel iteration over multiple containers
-- Lua Version: 5.1+
--
-- Demonstrates: coroutine-based zip iterators, shortest-container truncation, exhaustion reporting, iterator adapters

-- table.unpack arrived in Lua 5.2; on 5.1 the global unpack() does the job.
local unpack_values = table.unpack or unpack

-- ---------------------------------------------------------------------------
-- Zipping containers
--
-- Every variant below is a coroutine. The coroutine holds the loop state and
-- yields one row at a time; the wrapper hands those rows to a generic `for`
-- loop and turns "the coroutine is finished" into the nil that ends it.
-- ---------------------------------------------------------------------------

--- Walk several containers in parallel, stopping at the shortest one.
-- One element is pulled from each container per step; a container that has run
-- out of elements ends the walk, so the extra elements of the longer
-- containers are never visited.
-- @param ... the containers to walk; each is an array-like table
-- @return function an iterator yielding one value per container
local function zip(...)
  local lists = { ... }
  local count = #lists
  local finished = false
  local co = coroutine.wrap(function()
    if count == 0 then
      finished = true
      return
    end
    local index = 1
    while true do
      local row = {}
      local complete = true
      for i = 1, count do
        local value = lists[i][index]
        if value == nil then
          complete = false
        end
        row[i] = value
      end
      if not complete then
        finished = true
        return
      end
      coroutine.yield(unpack_values(row, 1, count))
      index = index + 1
    end
  end)
  return function()
    if finished then
      return nil
    end
    return co()
  end
end

--- Walk several containers in parallel, keeping the longer ones going.
-- A container that runs out is reported instead of ending the walk: the
-- second return value is the index of the first container that ran out, and
-- it stays nil while every container still has an element. The rows that
-- follow carry nil in the slot of the container that ran out.
-- @param ... the containers to walk; each is an array-like table
-- @return function an iterator yielding a row table and the exhausted index
local function zip_report(...)
  local lists = { ... }
  local count = #lists
  local finished = false
  local co = coroutine.wrap(function()
    if count == 0 then
      finished = true
      return
    end
    local index = 1
    local exhausted = nil
    while true do
      local row = {}
      local alive = 0
      for i = 1, count do
        local value = lists[i][index]
        if value == nil then
          if exhausted == nil then
            exhausted = i
          end
        else
          alive = alive + 1
        end
        row[i] = value
      end
      if alive == 0 then
        finished = true
        return
      end
      coroutine.yield(row, exhausted)
      index = index + 1
    end
  end)
  return function()
    if finished then
      return nil
    end
    return co()
  end
end

--- Walk several sources in parallel, stopping at the shortest one.
-- A source is any function that returns its next element, or nil once it is
-- exhausted. The sources are advanced in order and a step stops at the first
-- exhausted source, so a source that outlives the others keeps the elements
-- it has not been asked for yet.
-- @param ... the source functions to walk
-- @return function an iterator yielding one value per source
local function zip_iterators(...)
  local sources = { ... }
  local count = #sources
  local finished = false
  local co = coroutine.wrap(function()
    if count == 0 then
      finished = true
      return
    end
    while true do
      local row = {}
      local complete = true
      for i = 1, count do
        local value = sources[i]()
        if value == nil then
          complete = false
          break
        end
        row[i] = value
      end
      if not complete then
        finished = true
        return
      end
      coroutine.yield(unpack_values(row, 1, count))
    end
  end)
  return function()
    if finished then
      return nil
    end
    return co()
  end
end

--- Adapt a classic Lua iterator to a source.
-- A classic iterator is a triple: the control function, the state and the
-- initial control value. The control function is called the way a generic
-- `for` calls it, as `control(state, control_value)`, and the first result
-- of each call becomes the next control value. The element is the second
-- result -- that is where both the `ipairs` and the `next` iterator put it.
-- @param control the control function
-- @param state the iterator state
-- @param initial the initial control value
-- @return function a source returning the next element, or nil
local function pull(control, state, initial)
  local ctrl = initial
  return function()
    local results = { control(state, ctrl) }
    ctrl = results[1]
    return results[2]
  end
end

--- Produce the first `count` Fibonacci numbers as a source.
-- @param count how many numbers to produce
-- @return function a source returning the next number, or nil
local function fibonacci(count)
  local produced = 0
  local a, b = 0, 1
  return function()
    if produced >= count then
      return nil
    end
    produced = produced + 1
    local value = a
    a, b = b, a + b
    return value
  end
end

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

local names = { "ada", "grace", "alan", "edsger" }
local scores = { 95, 87, 92 }

-- zip stops at the shortest container.
local rows = {}
for name, score in zip(names, scores) do
  rows[#rows + 1] = { name, score }
end
assert(#rows == 3)
assert(rows[1][1] == "ada" and rows[1][2] == 95)
assert(rows[2][1] == "grace" and rows[2][2] == 87)
assert(rows[3][1] == "alan" and rows[3][2] == 92)

-- Each call to zip() starts a fresh walk, so the same iterator can be reused.
local zipped = zip(names, scores)
assert(zipped() == "ada")
assert(zipped() == "grace")
assert(zipped() == "alan")
assert(zipped() == nil)

-- Three containers at once.
local triples = {}
for number, letter, flag in zip({ 1, 2 }, { "x", "y" }, { true, false }) do
  triples[#triples + 1] = { number, letter, flag }
end
assert(#triples == 2)
assert(triples[1][1] == 1 and triples[1][2] == "x" and triples[1][3] == true)
assert(triples[2][1] == 2 and triples[2][2] == "y" and triples[2][3] == false)

-- An empty container ends the walk immediately.
assert(zip({ 1, 2 }, {})() == nil)
assert(zip()() == nil)

-- The reporting variant keeps the longer container going and says which
-- container ran out.
local report = {}
for row, exhausted in zip_report(names, scores) do
  report[#report + 1] = { row, exhausted }
end
assert(#report == 4)
assert(report[1][1][1] == "ada" and report[1][2] == nil)
assert(report[3][1][2] == 92 and report[3][2] == nil)
assert(report[4][1][1] == "edsger" and report[4][1][2] == nil)
assert(report[4][2] == 2)

-- The report names the shortest container, and the walk still covers the
-- elements of the longer one.
local empty_first = {}
for row, exhausted in zip_report({}, { 1, 2 }) do
  empty_first[#empty_first + 1] = { row, exhausted }
end
assert(#empty_first == 2)
assert(empty_first[1][2] == 1)
assert(empty_first[2][1][2] == 2)

-- The source variant walks sources that are not arrays at all: a computed
-- stream next to an array seen through the standard library's iterator.
-- ipairs() hands back the control function, the table and the control value,
-- so pull() adapts that triple to a source.
local words = pull(ipairs({ "red", "green", "blue" }))
local stream = {}
for number, word in zip_iterators(fibonacci(5), words) do
  stream[#stream + 1] = { number, word }
end
assert(#stream == 3)
assert(stream[1][1] == 0 and stream[1][2] == "red")
assert(stream[2][1] == 1 and stream[2][2] == "green")
assert(stream[3][1] == 1 and stream[3][2] == "blue")

-- A source need not be an array: a hash table walked with next() works too.
local settings = pull(pairs({ retries = 3, timeout = 30 }))
local seen = {}
local mixed = {}
for number, value in zip_iterators(fibonacci(2), settings) do
  mixed[#mixed + 1] = { number, value }
  seen[value] = true
end
assert(#mixed == 2)
assert(mixed[1][1] == 0 and mixed[2][1] == 1)
assert(seen[3] == true and seen[30] == true)
assert(seen[8080] == nil)

-- A source that outlives the others keeps the elements that were not asked
-- for: the step stops at the first exhausted source instead of pulling past
-- it.
local left = fibonacci(5)
local right = pull(ipairs({ "a", "b", "c" }))
local short = zip_iterators(left, right)
assert(short() == 0)
assert(short() == 1)
assert(left() == 1)
assert(right() == "c")

-- Three sources at once, and the empty case.
local three = {}
for a, b, c in zip_iterators(fibonacci(3), pull(ipairs({ "p", "q" })), pull(ipairs({ 7 }))) do
  three[#three + 1] = { a, b, c }
end
assert(#three == 1)
assert(three[1][1] == 0 and three[1][2] == "p" and three[1][3] == 7)
assert(zip_iterators()() == nil)

print("✓ iterator-patterns tests passed")
