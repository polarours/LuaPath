-- Example 12: Data Structures
-- Chapter: 11-data-structures
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: stack, queue, linked list implementations using tables

--- Stack (LIFO) implementation
local Stack = {}
Stack.__index = Stack

function Stack.new()
  return setmetatable({items = {}}, Stack)
end

function Stack:push(item)
  self.items[#self.items + 1] = item
end

function Stack:pop()
  if #self.items == 0 then return nil, "stack underflow" end
  return table.remove(self.items)
end

function Stack:peek()
  return self.items[#self.items]
end

function Stack:isEmpty() return #self.items == 0 end
function Stack:size() return #self.items end

function Stack:tostring()
  local parts = {}
  for i = #self.items, 1, -1 do parts[#parts + 1] = tostring(self.items[i]) end
  return "[" .. table.concat(parts, " <- ") .. "]"
end

--- Queue (FIFO) implementation using circular-ish buffer
local Queue = {}
Queue.__index = Queue

function Queue.new()
  return setmetatable({items = {}, head = 1, tail = 0}, Queue)
end

function Queue:enqueue(item)
  self.tail = self.tail + 1
  self.items[self.tail] = item
end

function Queue:dequeue()
  if self:isEmpty() then return nil, "queue underflow" end
  local item = self.items[self.head]
  self.items[self.head] = nil
  self.head = self.head + 1
  if self.head > self.tail then
    self.items = {}
    self.head = 1
    self.tail = 0
  end
  return item
end

function Queue:peek()
  if self:isEmpty() then return nil end
  return self.items[self.head]
end

function Queue:isEmpty() return self.head > self.tail end
function Queue:size() return self.tail - self.head + 1 end

function Queue:tostring()
  local parts = {}
  for i = self.head, self.tail do parts[#parts + 1] = tostring(self.items[i]) end
  return "{" .. table.concat(parts, " -> ") .. "}"
end

--- Singly linked list
local Node = {}
Node.__index = Node

function Node.new(value, next_node)
  return setmetatable({value = value, next = next_node}, Node)
end

local LinkedList = {}
LinkedList.__index = LinkedList

function LinkedList.new()
  return setmetatable({head = nil, size = 0}, LinkedList)
end

function LinkedList:push_front(value)
  self.head = Node.new(value, self.head)
  self.size = self.size + 1
end

function LinkedList:pop_front()
  if not self.head then return nil, "list is empty" end
  local value = self.head.value
  self.head = self.head.next
  self.size = self.size - 1
  return value
end

function LinkedList:insert_after(node, value)
  if not node then return end
  node.next = Node.new(value, node.next)
  self.size = self.size + 1
end

function LinkedList:delete_after(node)
  if not node or not node.next then return end
  node.next = node.next.next
  self.size = self.size - 1
end

function LinkedList:find(pred)
  local cur = self.head
  while cur do
    if pred(cur.value) then return cur end
    cur = cur.next
  end
  return nil
end

function LinkedList:tostring()
  local parts = {}
  local cur = self.head
  while cur do
    parts[#parts + 1] = tostring(cur.value)
    cur = cur.next
  end
  return "head -> " .. table.concat(parts, " -> ") .. " -> nil"
end

local function main()
  print("=== Data Structures ===\n")

  -- 1. Stack
  print("1. Stack (LIFO):")
  local stack = Stack.new()
  stack:push("A")
  stack:push("B")
  stack:push("C")
  print(string.format("  after push A,B,C: %s", stack:tostring()))
  print(string.format("  peek: %s", stack:peek()))
  print(string.format("  pop: %s", stack:pop()))
  print(string.format("  pop: %s", stack:pop()))
  print(string.format("  size: %d, empty: %s", stack:size(), tostring(stack:isEmpty())))
  stack:pop()
  print(string.format("  after last pop: empty=%s", tostring(stack:isEmpty())))

  -- 2. Queue
  print("\n2. Queue (FIFO):")
  local queue = Queue.new()
  queue:enqueue("X")
  queue:enqueue("Y")
  queue:enqueue("Z")
  print(string.format("  after enqueue X,Y,Z: %s", queue:tostring()))
  print(string.format("  peek: %s", queue:peek()))
  print(string.format("  dequeue: %s", queue:dequeue()))
  print(string.format("  dequeue: %s", queue:dequeue()))
  print(string.format("  size: %d", queue:size()))
  queue:enqueue("W")
  print(string.format("  enqueue W: %s", queue:tostring()))

  -- 3. Linked list
  print("\n3. Singly Linked List:")
  local list = LinkedList.new()
  list:push_front(10)
  list:push_front(20)
  list:push_front(30)
  print(string.format("  after push_front 10,20,30: %s", list:tostring()))
  print(string.format("  pop_front: %d", list:pop_front()))
  print(string.format("  after pop_front: %s", list:tostring()))

  -- Find and insert after
  local node = list:find(function(v) return v == 10 end)
  if node then
    list:insert_after(node, 15)
    print(string.format("  insert_after(10, 15): %s", list:tostring()))
    list:delete_after(node)
    print(string.format("  delete_after(10): %s", list:tostring()))
  end

  -- Traversal
  print("  traversal:")
  local cur = list.head
  while cur do
    print(string.format("    node: %d", cur.value))
    cur = cur.next
  end

  print("\n✓ All data structure demos completed!")
end

main()
