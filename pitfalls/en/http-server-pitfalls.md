# HTTP Server Pitfalls

Common mistakes when building an HTTP server in Lua, especially for embedded or production use.

## 1. Buffering Entire Requests Into Memory

Parsing large request bodies into a single string can cause memory pressure on the GC.

```lua
-- BAD: loads entire body into a table
local ok, err = pcall(function()
  local data = socket:receive("*a") -- read until connection closes
end)

-- GOOD: stream-based parsing with buffer
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

Pitfall: `receive("*a")` reads until EOF — but HTTP clients may keep connections open with pipelined requests.

## 2. Not Handling Partial Headers

HTTP headers may arrive in multiple TCP packets. Parsing headers line-by-line without buffering leads to incomplete parsed data.

```lua
-- BAD: assumes all headers arrive in one receive()
local line = socket:receive("*l")
parse_header(line)

-- GOOD: accumulate bytes until blank line separates headers from body
local header_buf = ""
local found_blank = false
while not found_blank do
  local chunk = socket:receive(1) -- byte-by-byte is slow; use larger chunks
  header_buf = header_buf .. chunk
  if header_buf:match("\r?\n\r?\n$") then found_blank = true end
end
```

## 3. Missing Case-Insensitive Header Comparison

HTTP header names are case-insensitive (RFC 7230). Lookups must be case-insensitive.

```lua
-- BAD: exact string match fails for mixed-case headers
local content_type = headers["Content-Type"]

-- GOOD: normalize keys to lowercase or use helper lookup
local function get_header(headers, name)
  local lower = name:lower()
  for k, v in pairs(headers) do
    if k:lower() == lower then return v end
  end
  return nil
end
```

## 4. Not Validating Content-Length Against Body Size

A mismatch between `Content-Length` and actual body size leads to parsing errors.

```lua
-- BAD: trust Content-Length blindly
local expected_length = tonumber(req.headers["Content-Length"])
req.body = client:receive(expected_length)

-- GOOD: validate received body length matches Content-Length
if #req.body ~= expected_length then
  -- Possible truncation or extra data — abort or handle gracefully
end
```

## 5. Coroutine Yields Inside C API Functions

If you yield a coroutine while inside a Lua C API function (e.g., from an external library), undefined behavior may occur.

```lua
-- BAD: yielding during C library I/O
coroutine.wrap(function()
  local result = some_c_library.request() -- may not be resumable
  -- If this yields, the VM state becomes corrupted
end)
```

## 6. Race Conditions With Shared State in Middleware

Multiple coroutines handling different requests may share mutable tables (config, counters) without protection.

```lua
-- BAD: global request counter modified by concurrent handlers
request_count = (request_count or 0) + 1

-- GOOD: protect shared state or use per-request state
local count_lock = require("mutex").create() -- hypothetical synchronization primitive
count_lock:enter()
request_count = (request_count or 0) + 1
count_lock:leave()
```

## 7. Ignoring Connection Errors Silently

Swallowing network errors prevents debugging and recovery.

```lua
-- BAD: silent failure
local ok, err = pcall(handle_request, client)
if not ok then end -- error swallowed!

-- GOOD: log the error and close the connection
if not ok then
  print("[WARN] Request failed:", err)
  client:close()
end
```
