#!/usr/bin/env lua
-- check-exercise-solutions.lua
-- Runs the reference solutions in the exercise files and reports the ones
-- that do not work.
--
-- The solutions are the part of the exercises a reader trusts most: they
-- copy one, run it, and expect it to do what the text says. Most of them
-- carry their own assertions and print a line when they pass, so a solution
-- whose logic is wrong -- or whose assert fires -- is a solution that
-- teaches the wrong thing, and nothing else in the build notices.
--
-- The exercise *statements* are not checked: they are prompts to write a
-- function, so most of their samples call something that does not exist yet
-- and are meant to fail.
--
-- A few solutions are not standalone programs and cannot be run on their
-- own: a test file for the module in the previous block, a pattern sketch
-- whose helpers are never defined, and the infinite recursion a debugging
-- task asks the learner to find. Those are listed in ALLOWED with the
-- reason.
--
-- Usage: lua scripts/check-exercise-solutions.lua [--interpreter <path>]

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

-- The solutions that are not runnable on their own, and why.
--
-- A block matches an entry when any of its lines starts with one of the
-- prefixes, so the key survives edits elsewhere in the file. The comments
-- are translated, so an entry that matches a comment carries the prefix of
-- both language tracks.
local ALLOWED = {
  ["beginner-solutions.md"] = {
    {
      prefixes = { 'local M = require("mathutils")' },
      reason = "the test file for the module in the previous block",
    },
    {
      prefixes = { "-- Small script: Top-level pcall", "-- 小脚本：顶层 pcall" },
      reason = "a pattern sketch: main() and the other helpers are never defined",
    },
  },
  ["intermediate-solutions.md"] = {
    {
      prefixes = { "mt.__index = function(t, k) return t[k] end" },
      reason = "the infinite recursion the debugging task asks the learner to find",
    },
  },
}

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
  if not ok or not pipe then
    io.stderr:write("cannot list " .. dir .. "\n")
    os.exit(1)
  end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  if #out == 0 then
    -- A directory that yields nothing is missing or empty, and a gate that
    -- checks nothing still reports PASSED. Either way the reader is
    -- misled, so this is an error rather than a silent zero.
    io.stderr:write("no files found in " .. dir .. "\n")
    os.exit(1)
  end
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
    for _, prefix in ipairs(entry.prefixes) do
      for _, line in ipairs(block.lines) do
        local stripped = line:gsub("^%s+", "")
        if stripped:sub(1, #prefix) == prefix then
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

-- `timeout` is not everywhere, but where it is, it keeps a solution that
-- waits for input from hanging the build.
--
-- os.execute returns the exit code on Lua 5.1 and true on 5.2 and later, so
-- "== 0" is false on every modern interpreter and the solutions ran without
-- a timeout at all.
local timeout_probe = os.execute("command -v timeout >/dev/null 2>&1")
local has_timeout = timeout_probe == true or timeout_probe == 0

for _, dir in ipairs({ "en/exercises", "zh/exercises" }) do
  for _, path in ipairs(list_files(dir, "*-solutions.md")) do
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
            -- The solution runs in its own directory: a solution that writes a
            -- file must not leave it in the repository.
            --
            -- os.tmpname() hands back the name of a file it has already
            -- created, so the name has to be given back before it can be
            -- used for a directory. Without this the mkdir fails, the file
            -- below it cannot be created, and the solution is silently never
            -- run.
            local workdir = os.tmpname()
            os.remove(workdir)
            os.execute(string.format("mkdir -p %s", shell_quote(workdir)))
            local temp = workdir .. "/solution.lua"
            local output = workdir .. "/output.txt"
            local fh = io.open(temp, "w")
            if not fh then
              -- A solution that cannot be written out cannot be checked, and
              -- a check that quietly checks nothing is worse than no check.
              errors = errors + 1
              print(string.format("  %s: code block %d could not be written out", path, index))
            else
              fh:write(table.concat(block.lines, "\n"))
              fh:close()
              local command
              if has_timeout then
                command = string.format("cd %s && timeout %d %s solution.lua < /dev/null > %s 2>&1",
                  shell_quote(workdir), TIMEOUT, INTERPRETER, shell_quote(output))
              else
                command = string.format("cd %s && %s solution.lua < /dev/null > %s 2>&1",
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
print(string.format("Solutions run:     %d", checked))
print(string.format("Allowed fragments: %d", skipped))
print(string.format("Mismatched:        %d", errors))
print()

if errors > 0 then
  print("EXERCISE SOLUTION CHECK FAILED")
  os.exit(1)
end

print("EXERCISE SOLUTION CHECK PASSED")
