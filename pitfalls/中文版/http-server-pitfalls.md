# HTTP 服务器陷阱

在 Lua 中构建 HTTP 服务器时的常见错误，特别是用于嵌入式或生产环境时。

## 1. 将整个请求缓冲到内存中

将大型请求体解析为单个字符串会导致 GC 内存压力。

```lua
-- BAD: 将整个 body 加载到表格中
local ok, err = pcall(function()
  local data = socket:receive("*a") -- 读取到连接关闭
end)

-- GOOD: 使用缓冲区进行流式解析
local buffer = ""
function handle_request(client)
  while true do
    local chunk, err = client:receive(4096)
    if not chunk then break end
    buffer = buffer .. chunk
    if check_header_complete(buffer) then break end
  end
end
```

陷阱：`receive("*a")` 会读取到 EOF —— 但 HTTP 客户端可能会保持连接打开并使用管道化请求。

## 2. 未处理部分头部

HTTP 头部可能在多个 TCP 数据包中到达。逐行解析头部而不使用缓冲区会导致解析不完整的数据。

```lua
-- BAD: 假设所有头部在一次 receive() 中到达
local line = socket:receive("*l")
parse_header(line)

-- GOOD: 累积字节直到空行分隔头部和主体
local header_buf = ""
local found_blank = false
while not found_blank do
  local chunk = socket:receive(1) -- 逐字节很慢；使用更大的块
  header_buf = header_buf .. chunk
  if header_buf:match("\r?\n\r?\n$") then found_blank = true end
end
```

## 3. 缺少大小写不敏感的头部比较

HTTP 头部名称是不区分大小写的（RFC 7230）。查找必须不区分大小写。

```lua
-- BAD: 精确字符串匹配对混合大小写头部失败
local content_type = headers["Content-Type"]

-- GOOD: 将键标准化为小写或使用辅助查找
local function get_header(headers, name)
  local lower = name:lower()
  for k, v in pairs(headers) do
    if k:lower() == lower then return v end
  end
  return nil
end
```

## 4. 未验证 Content-Length 与实际 body 大小

`Content-Length` 与实际 body 大小不匹配会导致解析错误。

```lua
-- BAD: 盲目信任 Content-Length
local expected_length = tonumber(req.headers["Content-Length"])
req.body = client:receive(expected_length)

-- GOOD: 验证接收的 body 长度匹配 Content-Length
if #req.body ~= expected_length then
  -- 可能的截断或额外数据 —— 中止或优雅处理
end
```

## 5. 在 C API 函数内携程让步

如果在 Lua C API 函数内部让步携程（例如来自外部库），可能会出现未定义行为。

```lua
-- BAD: 在 C 库 I/O 期间让步
coroutine.wrap(function()
  local result = some_c_library.request() -- 可能不可恢复
  -- 如果这让步，VM 状态将损坏
end)
```

## 6. 中间件中共享状态的竞态条件

处理不同请求的多个携程可能会共享可变表格（配置、计数器）而无需保护。

```lua
-- BAD: 全局请求计数器被并发处理器修改
request_count = (request_count or 0) + 1

-- GOOD: 保护共享状态或使用每个请求的状态
local count_lock = require("mutex").create() -- 假设的同步原语
count_lock:enter()
request_count = (request_count or 0) + 1
count_lock:leave()
```

## 7. 忽略连接错误

吞没网络错误会阻止调试和恢复。

```lua
-- BAD: 静默失败
local ok, err = pcall(handle_request, client)
if not ok then end -- 错误被吞没了！

-- GOOD: 记录错误并关闭连接
if not ok then
  print("[WARN] Request failed:", err)
  client:close()
end
```
