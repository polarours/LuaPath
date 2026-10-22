-- The Lua C API surface, taken from the headers of the runtimes this
-- project supports (5.1, 5.3, 5.4 and 5.5) and from the 5.1 sources:
--
--   grep -hoE '\b(lua(L)?[A-Z]\w*)\b' /usr/include/lua5.4/*.h \
--       /usr/include/lua5.1/*.h | sort -u
--
-- A chapter that names a function the API does not have is teaching a
-- program that will not compile, so the names are checked.
local API = {
  "luaI_openlib", "luaL_Buffer", "luaL_Reg", "luaL_Stream", "luaL_addchar",
  "luaL_addgsub", "luaL_addlstring", "luaL_addsize", "luaL_addstring", "luaL_addvalue",
  "luaL_argcheck", "luaL_argerror", "luaL_argexpected", "luaL_buffaddr", "luaL_buffinit",
  "luaL_buffinitsize", "luaL_bufflen", "luaL_buffsub", "luaL_callmeta", "luaL_checkany",
  "luaL_checkint", "luaL_checkinteger", "luaL_checklong", "luaL_checklstring", "luaL_checknumber",
  "luaL_checkoption", "luaL_checkstack", "luaL_checkstring", "luaL_checktype", "luaL_checkudata",
  "luaL_checkunsigned", "luaL_checkversion", "luaL_checkversion_", "luaL_dofile", "luaL_dostring",
  "luaL_error", "luaL_execresult", "luaL_fileresult", "luaL_findtable", "luaL_getmetafield",
  "luaL_getmetatable", "luaL_getn", "luaL_getsubtable", "luaL_gsub", "luaL_intop",
  "luaL_len", "luaL_load", "luaL_loadbuffer", "luaL_loadbufferx", "luaL_loadfile",
  "luaL_loadfilex", "luaL_loadstring", "luaL_newlib", "luaL_newlibtable", "luaL_newmetatable",
  "luaL_newstate", "luaL_openlib", "luaL_openlibs", "luaL_opt", "luaL_optint",
  "luaL_optinteger", "luaL_optlong", "luaL_optlstring", "luaL_optnumber", "luaL_optstring",
  "luaL_optunsigned", "luaL_prepbuffer", "luaL_prepbuffsize", "luaL_pushfail", "luaL_pushresult",
  "luaL_pushresultsize", "luaL_putchar", "luaL_ref", "luaL_reg", "luaL_register",
  "luaL_requiref", "luaL_setfuncs", "luaL_setmetatable", "luaL_setn", "luaL_testudata",
  "luaL_tolstring", "luaL_traceback", "luaL_typeerror", "luaL_typename", "luaL_typerror",
  "luaL_unref", "luaL_where",
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
  if not ok or not pipe then return out end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return out
end

local known = {}
for _, name in ipairs(API) do known[name] = true end

local errors = 0
local checked = 0

local directories = { "en", "zh", "pitfalls/en", "pitfalls/中文版", "references" }
for _, dir in ipairs(directories) do
  for _, path in ipairs(list_files(dir, "*.md")) do
    local content = read_file(path)
    if content then
      -- Lua patterns have no word boundary, so the character in front of
      -- the name is captured and checked instead.
      for _, name in content:gmatch("([^%w_])([%w_]+)%s*%(") do
        -- Lua patterns have no non-capturing groups either, so the name is
        -- matched loosely and filtered here.
        if name:match("^lua[A-Z]") then
          checked = checked + 1
          if not known[name] then
            errors = errors + 1
            print(string.format("  %s: %s is not a Lua C API function", path, name))
          end
        end
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Names checked:    %d", checked))
print(string.format("Mismatched:        %d", errors))
print()

if errors > 0 then
  print("C API NAME CHECK FAILED")
  os.exit(1)
end

print("C API NAME CHECK PASSED")
