-- Example 9: Coroutine Patterns
-- Chapter: 08-coroutines
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: producer-consumer, coroutine pipelines, cooperative scheduling

--- Buffered channel: safe send/receive between coroutines
local function Channel(capacity)
  capacity = capacity or 8
  local buffer = {}
  local senders = {}
  local receivers = {}
  local closed = false

  local ch = {}

  function ch:send(item)
    if closed then error("send on closed channel") end
    if #buffer < capacity then
      buffer[#buffer + 1] = item
      if #receivers > 0 then
        local co = table.remove(receivers, 1)
        coroutine.resume(co)
      end
    else
      senders[#senders + 1] = coroutine.running()
      coroutine.yield()
    end
  end

  function ch:receive()
    if #buffer > 0 then
      local item = table.remove(buffer, 1)
      if #senders > 0 then
        local co = table.remove(senders, 1)
        coroutine.resume(co)
      end
      return item
    end
    if closed and #buffer == 0 then return nil end
    receivers[#receivers + 1] = coroutine.running()
    coroutine.yield()
    if #buffer > 0 then
      local item = table.remove(buffer, 1)
      if #senders > 0 then
        local co = table.remove(senders, 1)
        coroutine.resume(co)
      end
      return item
    end
    return nil
  end

  function ch:close()
    closed = true
    for _, co in ipairs(receivers) do coroutine.resume(co) end
    receivers = {}
  end

  function ch:length() return #buffer end
  return ch
end

--- Producer-consumer pattern
local function demo_producer_consumer()
  print("1. Producer-Consumer (buffered channel)")
  local ch = Channel(4)

  local producer = coroutine.create(function()
    for i = 1, 6 do
      print(string.format("  produce: %d", i))
      ch:send(i)
    end
    ch:close()
  end)

  local consumer = coroutine.create(function()
    while true do
      local val = ch:receive()
      if val == nil then break end
      print(string.format("  consume: %d", val))
    end
  end)

  coroutine.resume(producer)
  while coroutine.status(consumer) ~= "dead" do
    coroutine.resume(consumer)
  end
end

--- Generator pattern: infinite sequence yielded lazily
local function fibonacci()
  return coroutine.wrap(function()
    local a, b = 0, 1
    while true do
      coroutine.yield(a)
      a, b = b, a + b
    end
  end)
end

local function demo_generator()
  print("\n2. Generator Pattern (Fibonacci)")
  local gen = fibonacci()
  for _ = 1, 10 do
    print(string.format("  fib: %d", gen()))
  end
end

--- Coroutine pipeline: filter -> map -> reduce
local function pipeline_filter(pred, source)
  return coroutine.wrap(function()
    for v in source do
      if pred(v) then coroutine.yield(v) end
    end
  end)
end

local function pipeline_map(fn, source)
  return coroutine.wrap(function()
    for v in source do coroutine.yield(fn(v)) end
  end)
end

local function pipeline_reduce(fn, init, source)
  local acc = init
  for v in source do acc = fn(acc, v) end
  return acc
end

local function demo_pipeline()
  print("\n3. Coroutine Pipeline (filter -> map -> reduce)")
  local nums = coroutine.wrap(function()
    for i = 1, 20 do coroutine.yield(i) end
  end)

  local evens = pipeline_filter(function(n) return n % 2 == 0 end, nums)
  local squared = pipeline_map(function(n) return n * n end, evens)
  local sum = pipeline_reduce(function(a, b) return a + b end, 0, squared)
  print(string.format("  Sum of squares of even numbers 1..20: %d", sum))
end

--- Fan-out / fan-in: multiple workers, single collector
local function demo_fanout_fanin()
  print("\n4. Fan-Out / Fan-In")
  local results = Channel(16)
  local done_count = 0
  local total_workers = 3

  for id = 1, total_workers do
    coroutine.resume(coroutine.create(function()
      for i = 1, 4 do
        local item = string.format("worker%d-item%d", id, i)
        results:send(item)
      end
    end))
  end
  results:close()

  local collected = {}
  while true do
    local item = results:receive()
    if item == nil then break end
    collected[#collected + 1] = item
  end
  print(string.format("  Collected %d items:", #collected))
  for _, v in ipairs(collected) do
    print(string.format("    %s", v))
  end
end

local function main()
  print("=== Coroutine Patterns ===\n")
  demo_producer_consumer()
  demo_generator()
  demo_pipeline()
  demo_fanout_fanin()
  print("\n✓ All coroutine pattern demos completed!")
end

main()
