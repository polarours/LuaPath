#!/usr/bin/env lua
-- check-pitfall-examples.lua
-- Runs the code samples in the pitfall articles and reports the ones that
-- do not work.
--
-- A pitfall article is a piece of teaching material: a reader copies the
-- sample and runs it. A sample that dies on the first line -- an undefined
-- global, a missing __index, a table that was never created -- teaches
-- nothing but a stack trace, and nothing else in the build notices.
--
-- Some samples are deliberately not runnable on their own: the FFI example
-- needs LuaJIT, and the server examples are fragments that continue the
-- surrounding text. Those are listed in ALLOWED with the reason.
--
-- Usage: lua scripts/check-pitfall-examples.lua [--interpreter <path>]

local INTERPRETER = "lua"
local TIMEOUT = 15

do
  local i = 1
  while arg[i] do
    if arg[i] == "--interpreter" then
      INTERPRETER = arg[i + 1] or INTERPRETER
      i = i + 1
    end
    i = i + 1
  end
end

-- The samples that are not runnable on their own, and why.
--
-- A block matches an entry when any of its lines starts with the prefix, so
-- the key survives edits elsewhere in the article. The optional "only" list
-- restricts an entry to the runtimes where the failure is expected.
local ALLOWED = {
  ["coroutine-c-boundary.md"] = {
    { prefix = 'local ffi = require("ffi")', reason = "needs LuaJIT's FFI library" },
  },
  ["http-server-pitfalls.md"] = {
    { prefix = "-- BAD:", reason = "server-side fragment: continues the surrounding text" },
  },
  ["rawlen-vs-length.md"] = {
    {
      prefix = "print(rawlen(t))",
      reason = "demonstrates that rawlen does not exist before Lua 5.2",
      only = { ["5.1"] = true, ["LuaJIT"] = true },
    },
  },
}

-- Which runtime is running the samples?
local RUNTIME
if type(jit) == "table" then
  RUNTIME = "LuaJIT"
else
  RUNTIME = _VERSION:match("(%d+%.%d+)")
end

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

local function list_files(dir, pattern)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format(
    "find %s -type f -name '%s' | sort", "'" .. dir:gsub("'", "'\\''") .. "'", pattern))
  if not ok or not pipe then return out end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return out
end

-- The fenced code blocks of a markdown file, as { lang, lines }.
local function code_blocks(content)
  local blocks = {}
  local lines = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  local i = 1
  while i <= #lines do
    local fence = lines[i]:match("^%s*```(.*)$")
    if fence then
      local lang = fence:match("^%s*(%S*)") or ""
      local body = {}
      i = i + 1
      while i <= #lines and not lines[i]:match("^%s*```") do
        body[#body + 1] = lines[i]
        i = i + 1
      end
      blocks[#blocks + 1] = { lang = lang:lower(), lines = body }
    end
    i = i + 1
  end
  return blocks
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Is this block one of the known fragments?
local function allowed_for(file_name, block)
  local entries = ALLOWED[file_name]
  if not entries then return nil end
  for _, entry in ipairs(entries) do
    if not entry.only or entry.only[RUNTIME] then
      for _, line in ipairs(block.lines) do
        local stripped = line:gsub("^%s+", "")
        if stripped:sub(1, #entry.prefix) == entry.prefix then
          return entry.reason
        end
      end
    end
  end
  return nil
end

local errors = 0
local checked = 0
local skipped = 0

-- `timeout` is not everywhere, but where it is, it keeps a sample that
-- waits for input from hanging the build.
local has_timeout = os.execute("command -v timeout >/dev/null 2>&1") == 0

for _, dir in ipairs({ "pitfalls/en", "pitfalls/中文版" }) do
  for _, path in ipairs(list_files(dir, "*.md")) do
    local content = read_file(path)
    if content then
      local file_name = path:match("([^/]+)$")
      for index, block in ipairs(code_blocks(content)) do
        if block.lang == "lua" then
          local reason = allowed_for(file_name, block)
          if reason then
            skipped = skipped + 1
          else
            checked = checked + 1
            -- The sample runs in its own directory: a sample that writes a
            -- file must not leave it in the repository.
            local workdir = os.tmpname()
            os.execute(string.format("mkdir -p %s", shell_quote(workdir)))
            local temp = workdir .. "/sample.lua"
            local output = workdir .. "/output.txt"
            local fh = io.open(temp, "w")
            if fh then
              fh:write(table.concat(block.lines, "\n"))
              fh:close()
              local command
              if has_timeout then
                command = string.format("cd %s && timeout %d %s sample.lua < /dev/null > %s 2>&1",
                  shell_quote(workdir), TIMEOUT, INTERPRETER, shell_quote(output))
              else
                command = string.format("cd %s && %s sample.lua < /dev/null > %s 2>&1",
                  shell_quote(workdir), INTERPRETER, shell_quote(output))
              end
              local ok = os.execute(command)
              if ok ~= true and ok ~= 0 then
                errors = errors + 1
                print(string.format("  %s: code block %d does not run", path, index))
                local out = io.open(output, "r")
                if out then
                  local text = out:read("*a")
                  out:close()
                  for line in (text .. "\n"):gmatch("(.-)\n") do
                    if line ~= "" then
                      print("      " .. line)
                    end
                  end
                end
              end
              os.remove(temp)
              os.remove(output)
              os.execute(string.format("rm -rf %s", shell_quote(workdir)))
            end
          end
        end
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Samples run:        %d", checked))
print(string.format("Allowed fragments:   %d", skipped))
print(string.format("Mismatched:          %d", errors))
print()

if errors > 0 then
  print("PITFALL EXAMPLE CHECK FAILED")
  os.exit(1)
end

print("PITFALL EXAMPLE CHECK PASSED")
