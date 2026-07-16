--[[
  Example: CLI Framework
  Chapter: Stage 9 — Advanced
  Difficulty: Advanced
  Lua Version: 5.1+
  Demonstrates: Argument parsing, help generation, flag/option handling
]]

local cli = {}

function cli.new(name, version, description)
  return setmetatable({
    name = name,
    version = version,
    description = description,
    flags = {},
    options = {},
    positionals = {},
  }, { __index = cli })
end

function cli:flag(short, long, desc)
  table.insert(self.flags, { short = short, long = long, desc = desc })
  return self
end

function cli:option(short, long, desc, default)
  table.insert(self.options, { short = short, long = long, desc = desc, default = default })
  return self
end

function cli:positional(name, desc)
  table.insert(self.positionals, { name = name, desc = desc })
  return self
end

function cli:parse(argv)
  local result = { _positionals = {}, _flags = {}, _options = {} }
  local i = 1
  local positional_idx = 1

  while i <= #argv do
    local arg = argv[i]

    if arg == "--help" or arg == "-h" then
      self:show_help(); os.exit(0)
    elseif arg == "--version" or arg == "-v" then
      print(self.name .. " v" .. self.version); os.exit(0)
    elseif arg:match("^%-%-%-?(.+)") then
      local long = arg:match("^%-%-%-?(.+)")
      for _, opt in ipairs(self.options) do
        if opt.long == long then
          i = i + 1
          result._options[opt.long] = argv[i] or opt.default
        end
      end
      for _, fl in ipairs(self.flags) do
        if fl.long == long then result._flags[fl.long] = true end
      end
    elseif arg:match("^%-(.)$") then
      local short = arg:match("^%-(.)$")
      for _, opt in ipairs(self.options) do
        if opt.short == short then
          i = i + 1
          result._options[opt.long] = argv[i] or opt.default
        end
      end
      for _, fl in ipairs(self.flags) do
        if fl.short == short then result._flags[fl.long] = true end
      end
    else
      result._positionals[positional_idx] = arg
      positional_idx = positional_idx + 1
    end
    i = i + 1
  end

  -- Apply defaults for missing options
  for _, opt in ipairs(self.options) do
    if not result._options[opt.long] then
      result._options[opt.long] = opt.default
    end
  end
  return result
end

function cli:show_help()
  print(self.name .. " v" .. self.version)
  print(self.description)
  print("\nUsage:")
  local parts = { self.name }
  for _, fl in ipairs(self.flags) do parts[#parts + 1] = "[" .. fl.long .. "]" end
  for _, opt in ipairs(self.options) do parts[#parts + 1] = "[" .. opt.long .. " <val>]" end
  for _, p in ipairs(self.positionals) do parts[#parts + 1] = p.name end
  print("  " .. table.concat(parts, " "))

  print("\nFlags:")
  for _, fl in ipairs(self.flags) do
    print(string.format("  -%s, --%-12s %s", fl.short, fl.long, fl.desc))
  end
  print("\nOptions:")
  for _, opt in ipairs(self.options) do
    print(string.format("  -%s, --%-12s %s (default: %s)", opt.short, opt.long, opt.desc, tostring(opt.default)))
  end
  print("\nArguments:")
  for _, p in ipairs(self.positionals) do
    print(string.format("  %-20s %s", p.name, p.desc))
  end
end

-- Test/demo
local function main()
  local app = cli.new("mytool", "1.0.0", "A sample CLI tool")
    :flag("v", "verbose", "Enable verbose output")
    :flag("q", "quiet", "Suppress output")
    :option("n", "name", "User name", "guest")
    :option("o", "output", "Output file", "out.txt")
    :positional("file", "Input file to process")

  local result = app:parse(arg or {})
  print("Parsed:")
  print("  Flags: " .. (result._flags.verbose and "verbose " or "") .. (result._flags.quiet and "quiet" or ""))
  print("  Name: " .. tostring(result._options.name))
  print("  Output: " .. tostring(result._options.output))
  print("  Positionals: " .. tostring(result._positionals[1]))
  print("\n[OK] CLI framework working")
end

main()
