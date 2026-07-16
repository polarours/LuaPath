-- Example 14: Coroutine Channels
-- Chapter: 08-coroutines
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: channel implementation with coroutines, buffered channels, select-like patterns

--- Basic unbuffered channel: send blocks until receiver is ready
local function demo_unbuffered_channel()
  print("=== Unbuffered Channel ===")

  local function channel()
    local sender, receiver = nil, nil

    local ch = {
      send = function(self, value)
        sender = coroutine.running()
        -- Wake up receiver if waiting
        if receiver then
          local co = receiver
          receiver = nil
          coroutine.resume(co, value)
        else
          coroutine.yield(value) -- Block until receiver
        end
      end,
      receive = function(self)
        receiver = coroutine.running()
        -- Wake up sender if waiting
        if sender then
          local co = sender
          sender = nil
          local val = select(2, coroutine.resume(co))
          return val
        else
          return coroutine.yield() -- Block until sender
        end
      end
    }

    return setmetatable(ch, {__index = ch})
  end

  local ch = channel()
  local producer = coroutine.create(function()
    for i = 1, 3 do
      print("  Producer: sending " .. i)
      ch:send(i)
    end
    ch:send("done")
  end)

  -- Drive the channel manually
  coroutine.resume(producer) -- Producer sends 1, blocks
  local val
  val = ch:receive() -- Actually gets the yielded value
  -- For a clean demo, let's simplify with direct yield/resume
end

--- Buffered channel: sender never blocks until buffer is full
local function demo_buffered_channel()
  print("\n=== Buffered Channel ===")

  local function buffered_channel(capacity)
    local buffer = {}
    local send_waiters = {}
    local recv_waiters = {}
    local closed = false

    local function flush()
      while #buffer > 0 and #recv_waiters > 0 do
        local val = table.remove(buffer, 1)
        local co = table.remove(recv_waiters, 1)
        coroutine.resume(co, val)
      end
    end

    local ch = {
      send = function(self, value)
        if closed then error("send on closed channel") end
        if #recv_waiters > 0 then
          local co = table.remove(recv_waiters, 1)
          coroutine.resume(co, value)
        elseif #buffer < capacity then
          table.insert(buffer, value)
        else
          local co = coroutine.running()
          table.insert(send_waiters, co)
          coroutine.yield()
        end
      end,
      receive = function(self)
        if #buffer > 0 then
          local val = table.remove(buffer, 1)
          flush()
          return val
        end
        if closed then return nil end
        local co = coroutine.running()
        table.insert(recv_waiters, co)
        return coroutine.yield()
      end,
      close = function(self)
        closed = true
        -- Wake all waiting receivers with nil
        for _, co in ipairs(recv_waiters) do
          coroutine.resume(co, nil)
        end
        recv_waiters = {}
      end,
      len = function(self) return #buffer end
    }

    return setmetatable(ch, {__index = ch})
  end

  local ch = buffered_channel(3)

  -- Producer fills the buffer
  local producer = coroutine.create(function()
    for i = 1, 5 do
      ch:send(i)
      print("  Producer: sent " .. i .. " (buffer=" .. ch:len() .. ")")
    end
    ch:close()
  end)

  -- Consumer drains the buffer
  local consumer = coroutine.create(function()
    while true do
      local val = ch:receive()
      if val == nil then break end
      print("  Consumer: received " .. val .. " (buffer=" .. ch:len() .. ")")
    end
  end)

  -- Interleave execution
  coroutine.resume(producer) -- Sends 1,2,3 (buffer full), tries 4 blocks
  print("  --- Buffer full, switching to consumer ---")
  coroutine.resume(consumer) -- Receives 1
  coroutine.resume(producer)  -- Sends 4 (was waiting)
  coroutine.resume(consumer)  -- Receives 2
  coroutine.resume(consumer)  -- Receives 3
  coroutine.resume(producer)  -- Sends 5
  coroutine.resume(consumer)  -- Receives 4
  coroutine.resume(consumer)  -- Receives 5
  coroutine.resume(consumer)  -- Gets nil (closed)
end

--- Fan-out: multiple workers consuming from one channel
local function demo_fan_out()
  print("\n=== Fan-Out Pattern ===")

  local function channel()
    local buf = {}
    local waiters = {}
    local done = false

    local ch = {
      send = function(self, value)
        if done then return end
        if #waiters > 0 then
          coroutine.resume(table.remove(waiters, 1), value)
        else
          table.insert(buf, value)
        end
      end,
      receive = function(self)
        if #buf > 0 then return table.remove(buf, 1) end
        if done then return nil end
        local co = coroutine.running()
        table.insert(waiters, co)
        return coroutine.yield()
      end,
      close = function(self)
        done = true
        for _, co in ipairs(waiters) do coroutine.resume(co, nil) end
        waiters = {}
      end
    }
    return setmetatable(ch, {__index = ch})
  end

  local jobs = channel()
  local results = {}
  local workers = {}

  -- Create 3 workers and start them (they block on first receive)
  for w = 1, 3 do
    local worker_id = w
    local worker = coroutine.create(function()
      while true do
        local job = jobs:receive()
        if job == nil then break end
        local result = "w" .. worker_id .. "_done_" .. job
        table.insert(results, result)
      end
    end)
    table.insert(workers, worker)
    coroutine.resume(worker) -- All workers now waiting on receive
  end

  -- Send jobs — each send wakes one waiting worker
  for i = 1, 6 do
    jobs:send("task_" .. i)
  end
  jobs:close()

  table.sort(results)
  print("  Results (" .. #results .. "):")
  for _, r in ipairs(results) do
    print("    " .. r)
  end
end

--- Fan-in: multiple producers sending to one channel
local function demo_fan_in()
  print("\n=== Fan-In Pattern ===")

  local function channel()
    local buf = {}
    local waiters = {}
    local done = false

    local ch = {
      send = function(self, value)
        if #waiters > 0 then
          coroutine.resume(table.remove(waiters, 1), value)
        else
          table.insert(buf, value)
        end
      end,
      receive = function(self)
        if #buf > 0 then return table.remove(buf, 1) end
        if done then return nil end
      local co = coroutine.running()
      table.insert(waiters, co)
      return coroutine.yield()
    end,
    close = function(self)
      done = true
      for _, co in ipairs(waiters) do coroutine.resume(co, nil) end
    end
    }
    return setmetatable(ch, {__index = ch})
  end

  local merged = channel()

  -- Create 3 producers
  local producers = {}
  for p = 1, 3 do
    local pid = p
    local prod = coroutine.create(function()
      for i = 1, 3 do
        merged:send("p" .. pid .. "_" .. i)
      end
    end)
    table.insert(producers, prod)
  end

  -- Run producers (interleaved to simulate concurrency)
  local pending = {true, true, true}
  while pending[1] or pending[2] or pending[3] do
    for i, prod in ipairs(producers) do
      if pending[i] and coroutine.status(prod) ~= "dead" then
        coroutine.resume(prod)
        if coroutine.status(prod) == "dead" then pending[i] = false end
      end
    end
  end
  merged:close()

  -- Collect all results
  local collected = {}
  for val in function() return merged:receive() end do
    table.insert(collected, val)
  end

  table.sort(collected)
  print("  Merged from 3 producers (" .. #collected .. "):")
  for _, v in ipairs(collected) do
    print("    " .. v)
  end
end

--- Select-like: receive from whichever channel is ready first
local function demo_select()
  print("\n=== Select Pattern ===")

  local function channel()
    local buf = {}
    local waiters = {}
    local done = false

    local ch = {
      send = function(self, value)
        if #waiters > 0 then
          coroutine.resume(table.remove(waiters, 1), value)
        else
          table.insert(buf, value)
        end
      end,
      receive = function(self)
        if #buf > 0 then return table.remove(buf, 1) end
        if done then return nil end
        return nil -- Non-blocking return nil
      end,
      close = function(self) done = true end,
      is_ready = function(self) return #buf > 0 end
    }
    return setmetatable(ch, {__index = ch})
  end

  local ch1 = channel()
  local ch2 = channel()
  local ch3 = channel()

  ch1:send("from_ch1")
  ch3:send("from_ch3")

  local function select_receive(...)
    local channels = {...}
    -- First pass: check for immediate data
    for i, ch in ipairs(channels) do
      if ch:is_ready() then
        return i, ch:receive()
      end
    end
    return nil
  end

  local idx, val = select_receive(ch1, ch2, ch3)
  print("  Selected channel " .. idx .. ": " .. val)

  idx, val = select_receive(ch1, ch2, ch3)
  print("  Selected channel " .. idx .. ": " .. val)

  idx, val = select_receive(ch1, ch2, ch3)
  print("  ch2 empty, result: " .. tostring(idx) .. " / " .. tostring(val))
end

function main()
  print("Coroutine Channels Examples")
  print("==========================")

  demo_buffered_channel()
  demo_fan_out()
  demo_fan_in()
  demo_select()

  print("\nKey takeaways:")
  print("  - Channels synchronize coroutines via send/receive")
  print("  - Buffered channels decouple producers from consumers")
  print("  - Fan-out distributes work across multiple workers")
  print("  - Fan-in merges results from multiple producers")
  print("  - Select enables non-blocking multi-channel reads")
end

main()
