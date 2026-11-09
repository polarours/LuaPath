-- The Lua C API surface, taken from the headers of the runtimes this
-- project supports (5.1 and 5.4) and from the 5.1 sources:
--
--   grep -hoE '\blua_?[A-Za-z][A-Za-z0-9_]*\b' /usr/include/lua5.4/*.h \
--       /usr/include/lua5.1/*.h | sort -u
--
-- A chapter that calls a function the API does not have is teaching a
-- program that will not compile, so the names are checked.
--
-- Only the call sites are checked, not every mention: the documents talk
-- about families of functions ("the luaL_check* functions") and about tools
-- whose names start with "lua" (luajit, luarocks, luaunit), and none of
-- those are API names. The earlier inventory held the auxiliary library
-- only, so a call to a core function that does not exist -- such as the
-- Lua 5.0 spelling lua_pushfunction -- went unnoticed.
local API = {
  "luaI_openlib", "luaL_Buffer", "luaL_Reg", "luaL_Stream", "luaL_addchar", "luaL_addgsub", "luaL_addlstring",
  "luaL_addsize", "luaL_addstring", "luaL_addvalue", "luaL_argcheck", "luaL_argerror", "luaL_argexpected",
  "luaL_buffaddr", "luaL_buffinit", "luaL_buffinitsize", "luaL_bufflen", "luaL_buffsub", "luaL_callmeta",
  "luaL_checkany", "luaL_checkint", "luaL_checkinteger", "luaL_checklong", "luaL_checklstring", "luaL_checknumber",
  "luaL_checkoption", "luaL_checkstack", "luaL_checkstring", "luaL_checktype", "luaL_checkudata",
  "luaL_checkunsigned", "luaL_checkversion", "luaL_checkversion_", "luaL_dofile", "luaL_dostring", "luaL_error",
  "luaL_execresult", "luaL_fileresult", "luaL_findtable", "luaL_getmetafield", "luaL_getmetatable", "luaL_getn",
  "luaL_getsubtable", "luaL_gsub", "luaL_intop", "luaL_len", "luaL_load", "luaL_loadbuffer", "luaL_loadbufferx",
  "luaL_loadfile", "luaL_loadfilex", "luaL_loadstring", "luaL_newlib", "luaL_newlibtable", "luaL_newmetatable",
  "luaL_newstate", "luaL_openlib", "luaL_openlibs", "luaL_opt", "luaL_optint", "luaL_optinteger", "luaL_optlong",
  "luaL_optlstring", "luaL_optnumber", "luaL_optstring", "luaL_optunsigned", "luaL_prepbuffer", "luaL_prepbuffsize",
  "luaL_pushfail", "luaL_pushresult", "luaL_pushresultsize", "luaL_putchar", "luaL_ref", "luaL_reg", "luaL_register",
  "luaL_requiref", "luaL_setfuncs", "luaL_setmetatable", "luaL_setn", "luaL_testudata", "luaL_tolstring",
  "luaL_traceback", "luaL_typeerror", "luaL_typename", "luaL_typerror", "luaL_unref", "luaL_where", "lua_absindex",
  "lua_arith", "lua_assert", "lua_atpanic", "lua_c", "lua_call", "lua_callk", "lua_checkstack", "lua_close",
  "lua_closeslot", "lua_closethread", "lua_compare", "lua_concat", "lua_copy", "lua_cpcall", "lua_createtable",
  "lua_dump", "lua_equal", "lua_error", "lua_freeline", "lua_gc", "lua_getallocf", "lua_getextraspace", "lua_getfenv",
  "lua_getfield", "lua_getgccount", "lua_getglobal", "lua_gethook", "lua_gethookcount", "lua_gethookmask", "lua_geti",
  "lua_getinfo", "lua_getiuservalue", "lua_getlocal", "lua_getlocaledecpoint", "lua_getmetatable", "lua_getref",
  "lua_getregistry", "lua_getstack", "lua_gettable", "lua_gettop", "lua_getupvalue", "lua_getuservalue", "lua_h",
  "lua_ident", "lua_insert", "lua_integer2str", "lua_isboolean", "lua_iscfunction", "lua_isfunction", "lua_isinteger",
  "lua_islightuserdata", "lua_isnil", "lua_isnone", "lua_isnoneornil", "lua_isnumber", "lua_isstring", "lua_istable",
  "lua_isthread", "lua_isuserdata", "lua_isyieldable", "lua_len", "lua_lessthan", "lua_load", "lua_newstate",
  "lua_newtable", "lua_newthread", "lua_newuserdata", "lua_newuserdatauv", "lua_next", "lua_number2int",
  "lua_number2integer", "lua_number2str", "lua_number2strx", "lua_numbertointeger", "lua_objlen", "lua_open",
  "lua_pcall", "lua_pcallk", "lua_pclose", "lua_pointer2str", "lua_pop", "lua_popen", "lua_pushboolean",
  "lua_pushcclosure", "lua_pushcfunction", "lua_pushfstring", "lua_pushglobaltable", "lua_pushinteger",
  "lua_pushlightuserdata", "lua_pushliteral", "lua_pushlstring", "lua_pushnil", "lua_pushnumber", "lua_pushstring",
  "lua_pushthread", "lua_pushunsigned", "lua_pushvalue", "lua_pushvfstring", "lua_rawequal", "lua_rawget",
  "lua_rawgeti", "lua_rawgetp", "lua_rawlen", "lua_rawset", "lua_rawseti", "lua_rawsetp", "lua_readline", "lua_ref",
  "lua_register", "lua_remove", "lua_replace", "lua_resetthread", "lua_resume", "lua_rotate", "lua_saveline",
  "lua_setallocf", "lua_setcstacklimit", "lua_setfenv", "lua_setfield", "lua_setglobal", "lua_sethook", "lua_seti",
  "lua_setiuservalue", "lua_setlevel", "lua_setlocal", "lua_setmetatable", "lua_settable", "lua_settop",
  "lua_setupvalue", "lua_setuservalue", "lua_setwarnf", "lua_status", "lua_stdin_is_tty", "lua_str2number",
  "lua_stringtonumber", "lua_strlen", "lua_strx2number", "lua_tmpnam", "lua_toboolean", "lua_tocfunction",
  "lua_toclose", "lua_tointeger", "lua_tointegerx", "lua_tolstring", "lua_tonumber", "lua_tonumberx", "lua_topointer",
  "lua_tostring", "lua_tothread", "lua_tounsigned", "lua_tounsignedx", "lua_touserdata", "lua_type", "lua_typename",
  "lua_unref", "lua_upvalueid", "lua_upvalueindex", "lua_upvaluejoin", "lua_version", "lua_warning", "lua_writeline",
  "lua_writestring", "lua_writestringerror", "lua_xmove", "lua_yield", "lua_yieldk",
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
      -- the name is captured and checked instead. A dot is not a valid
      -- front character either: "mymod.lua (loaded in order)" would
      -- otherwise be read as a call to a function called "lua".
      --
      -- The leading newline makes sure a name at the very start of a file
      -- still has a character in front of it.
      for _, name in ("\n" .. content):gmatch("([^%w_.])([%w_]+)%s*%(") do
        -- Lua patterns have no non-capturing groups either, so the name is
        -- matched loosely and filtered here.
        if name:match("^lua[A-Z_]") then
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
