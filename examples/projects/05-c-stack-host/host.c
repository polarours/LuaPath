/*
 * host.c -- C API example for Chapter 11 (Lua C API)
 *
 * Demonstrates, in order of the chapter's sections:
 *   1. Stack protocol (gettop/settop/absindex) and the call contract
 *   2. Writing a C function with luaL_check* argument validation
 *   3. String handling with luaL_checklstring (length, not NUL-termination)
 *   4. Table operations from C (rawlen/rawgeti, no rehash during iteration)
 *   5. Userdata with a metatable, __index, __len and __tostring
 *   6. Error handling: luaL_error vs lua_error, plus lua_pcall on the host side
 *   7. The registry as a C-side storage that Lua cannot reach directly
 *
 * The shims below let the same file compile against Lua 5.1 through 5.4; the
 * version differences are exactly what a portable embedder has to handle.
 */

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

/* ---- version shims (5.1 -> 5.4) -------------------------------------- */

#ifndef LUA_OK                       /* 5.2+ */
#define LUA_OK 0
#endif

#if LUA_VERSION_NUM < 502
#define lua_rawlen lua_objlen        /* renamed in 5.2 */
#define LUA_RIDX_MAINTHREAD 1        /* does not exist on 5.1 */
#endif

#if LUA_VERSION_NUM < 502
/* luaL_setfuncs arrived in 5.2; register into a table on the stack instead */
static void shim_setfuncs(lua_State *L, const luaL_Reg *regs, int nup) {
  (void)nup;
  luaL_register(L, NULL, regs);      /* NULL => only the given functions */
}
#define luaL_setfuncs shim_setfuncs
#endif

/* ---- 1. stack protocol ------------------------------------------------ */

static const char *stack_shape(lua_State *L) {
  /* Returns a short description of the live stack range. Buffer is static so
   * the demo below can print it immediately without leaking to the caller. */
  static char buf[128];
  int top = lua_gettop(L);
  int i;
  buf[0] = '\0';
  for (i = 1; i <= top && i <= 8; i++) {
    const char *t = luaL_typename(L, i);
    if (i > 1) strncat(buf, ",", sizeof(buf) - strlen(buf) - 1);
    strncat(buf, t, sizeof(buf) - strlen(buf) - 1);
  }
  if (top == 0) snprintf(buf, sizeof(buf), "<empty>");
  return buf;
}

/* ---- 2. writing a C function ----------------------------------------- */

static int c_sum(lua_State *L) {
  int nargs = lua_gettop(L);
  lua_Integer total = 0;
  int i;
  for (i = 1; i <= nargs; i++)
    total += luaL_checkinteger(L, i);   /* raises a Lua error on a bad arg */
  lua_pushinteger(L, total);
  return 1;                             /* one result on the stack */
}

static int c_sum_checked(lua_State *L) {
  int nargs = lua_gettop(L);
  int i;
  for (i = 1; i <= nargs; i++) {
    if (!lua_isnumber(L, i)) {
      /* assert-style: push nothing and raise, so the caller sees a clean error */
      return luaL_error(L, "sum: argument #%d must be a number, got %s",
                        i, luaL_typename(L, i));
    }
  }
  {
    lua_Number total = 0;
    for (i = 1; i <= nargs; i++) total += lua_tonumber(L, i);
    lua_pushnumber(L, total);
  }
  return 1;
}

/* ---- 3. string handling ---------------------------------------------- */

static int c_strlen(lua_State *L) {
  size_t len;
  /* luaL_checklstring returns the length: Lua strings are binary-safe, so the
   * embedded NUL (if any) must not be measured with strlen(). */
  const char *s = luaL_checklstring(L, 1, &len);
  lua_pushinteger(L, (lua_Integer)len);
  lua_pushinteger(L, (lua_Integer)strlen(s));
  return 2;                             /* length, and C-string length */
}

static int c_has_embedded_nul(lua_State *L) {
  size_t len;
  const char *s = luaL_checklstring(L, 1, &len);
  lua_pushboolean(L, len > strlen(s));
  return 1;
}

/* ---- 4. table operations --------------------------------------------- */

static int c_table_sum(lua_State *L) {
  lua_Integer n, i, total = 0;
  luaL_checktype(L, 1, LUA_TTABLE);
  n = (lua_Integer)lua_rawlen(L, 1);
  for (i = 1; i <= n; i++) {
    lua_rawgeti(L, 1, i);               /* stack: table -> table, value */
    if (lua_isnumber(L, -1))
      total += (lua_Integer)lua_tointeger(L, -1);
    lua_pop(L, 1);                      /* pop the value, leave the table */
  }
  lua_pushinteger(L, total);
  lua_pushinteger(L, n);                /* also report how many slots were read */
  return 2;
}

static int c_table_keys(lua_State *L) {
  lua_Integer count = 0;
  luaL_checktype(L, 1, LUA_TTABLE);
  lua_pushnil(L);
  /* NOTE: nothing is added to the table inside this loop, so rehashing (which
   * would invalidate the iterator) cannot happen -- the safe pattern. */
  while (lua_next(L, 1) != 0) {
    lua_pop(L, 1);                      /* pop the value, keep the key */
    count++;
  }
  lua_pushinteger(L, count);
  return 1;
}

/* ---- 5. userdata with a metatable ------------------------------------- */

typedef struct {
  double x, y;
} point_t;

#define POINT_MT "geom.point"

static point_t *check_point(lua_State *L, int idx) {
  return (point_t *)luaL_checkudata(L, idx, POINT_MT);
}

static int point_length(lua_State *L) {
  point_t *p = check_point(L, 1);
  lua_pushnumber(L, sqrt(p->x * p->x + p->y * p->y));
  return 1;
}

static int point_index(lua_State *L) {
  point_t *p = check_point(L, 1);
  const char *field = luaL_checkstring(L, 2);
  if (strcmp(field, "x") == 0) { lua_pushnumber(L, p->x); return 1; }
  if (strcmp(field, "y") == 0) { lua_pushnumber(L, p->y); return 1; }
  if (strcmp(field, "kind") == 0) { lua_pushliteral(L, "point"); return 1; }
  return luaL_error(L, "point has no field '%s'", field);
}

static int point_tostring(lua_State *L) {
  point_t *p = check_point(L, 1);
  /* lua_pushfstring accepts only %s %d %f %c %p %% (plus %I/%U in 5.4) --
   * there are no width or precision specifiers, so %.1f is not an option. */
  lua_pushfstring(L, "point(%f, %f)", p->x, p->y);
  return 1;
}

static int c_new_point(lua_State *L) {
  point_t *p = (point_t *)lua_newuserdata(L, sizeof(point_t));
  p->x = luaL_checknumber(L, 1);
  p->y = luaL_checknumber(L, 2);

  /* Metatables live in the registry: create once, then attach. */
  if (luaL_newmetatable(L, POINT_MT)) {
    static const luaL_Reg methods[] = {
      { "__index",    point_index    },
      { "__len",      point_length   },
      { "__tostring", point_tostring },
      { NULL, NULL }
    };
    luaL_setfuncs(L, methods, 0);
  }
  lua_setmetatable(L, -2);
  return 1;
}

static int point_dot(lua_State *L) {
  point_t *a = check_point(L, 1);
  point_t *b = check_point(L, 2);
  lua_pushnumber(L, a->x * b->x + a->y * b->y);
  return 1;
}

/* ---- 6. error handling ----------------------------------------------- */

static int c_fail(lua_State *L) {
  return luaL_error(L, "deliberate failure triggered from C");
}

static int c_div(lua_State *L) {
  lua_Number a = luaL_checknumber(L, 1);
  lua_Number b = luaL_checknumber(L, 2);
  if (b == 0.0) {
    /* %g is not one of lua_pushfstring's specifiers (only %s %d %f %c %p %%),
     * so use %f -- otherwise luaL_error would raise on its own formatting. */
    return luaL_error(L, "division by zero: %f / 0", (double)a);
  }
  lua_pushnumber(L, a / b);
  return 1;
}

/* ---- 7. the registry -------------------------------------------------- */

static int c_cache_put(lua_State *L) {
  size_t len;
  const char *key = luaL_checklstring(L, 1, &len);
  lua_pushvalue(L, 2);                  /* the value */
  lua_setfield(L, LUA_REGISTRYINDEX, key);  /* registry[key] = value */
  return 0;
}

static int c_cache_get(lua_State *L) {
  size_t len;
  const char *key = luaL_checklstring(L, 1, &len);
  lua_getfield(L, LUA_REGISTRYINDEX, key);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushliteral(L, "not cached");
    return 2;
  }
  return 1;
}

/* ---- module registration ---------------------------------------------- */

static const luaL_Reg api[] = {
  { "sum",            c_sum            },
  { "sum_checked",    c_sum_checked    },
  { "strlen",         c_strlen         },
  { "has_embedded_nul", c_has_embedded_nul },
  { "table_sum",      c_table_sum      },
  { "table_keys",     c_table_keys     },
  { "new_point",      c_new_point      },
  { "point_dot",      point_dot        },
  { "fail",           c_fail           },
  { "div",            c_div            },
  { "cache_put",      c_cache_put      },
  { "cache_get",      c_cache_get      },
  { NULL, NULL }
};

int main(void) {
  lua_State *L = luaL_newstate();
  int status;
  int failures = 0;

  if (!L) {
    fprintf(stderr, "FATAL: could not create a Lua state\n");
    return 1;
  }
  luaL_openlibs(L);

#if LUA_VERSION_NUM < 502
  luaL_register(L, "chost", api);       /* creates the global table for us */
  lua_pop(L, 1);
#else
  lua_newtable(L);
  luaL_setfuncs(L, api, 0);
  lua_setglobal(L, "chost");
#endif

  /* Expose the compile-time version to the Lua chunk, so the assertions below
   * can branch on the behaviour differences that actually vary across the
   * supported range rather than assuming 5.4 everywhere. */
  lua_pushinteger(L, LUA_VERSION_NUM);
  lua_setglobal(L, "LUA_VERSION_NUM");

  printf("LUA_VERSION_NUM=%d\n", LUA_VERSION_NUM);

  /* 1. stack protocol: everything we push must be accounted for */
  lua_pushinteger(L, 7);
  lua_pushnumber(L, 1.5);
  lua_pushliteral(L, "s");
  printf("STACK after three pushes: %s (top=%d)\n",
         stack_shape(L), lua_gettop(L));
  if (lua_gettop(L) != 3) { printf("CHECK [FAIL] stack top should be 3\n"); failures++; }
  else printf("CHECK [ok  ] stack protocol counts three values\n");

  lua_settop(L, 0);                     /* 1.5 and "s" discarded */
  if (lua_gettop(L) != 0) { printf("CHECK [FAIL] settop(0) did not clear\n"); failures++; }
  else printf("CHECK [ok  ] lua_settop(L, 0) clears the frame\n");

  /* 2-7 are driven from Lua so the reader sees the call site and the result.
   * `expect()` counts every assertion and prints one line per failure; the
   * driver only ever asserts on LUA_FAILURES, so formatting differences between
   * Lua versions cannot silently turn a real failure into a pass. */
  status = luaL_loadstring(L,
    "local out, fails = {}, 0\n"
    "local function emit(s) out[#out+1] = s end\n"
    "local function expect(cond, name)\n"
    "  if cond then\n"
    "    emit(string.format('EXPECT [ok  ] %s', name))\n"
    "  else\n"
    "    fails = fails + 1\n"
    "    emit(string.format('EXPECT [FAIL] %s', name))\n"
    "  end\n"
    "end\n"
    "\n"
    "-- 2. C function + argument validation\n"
    "emit('SUM=' .. tostring(chost.sum(1,2,3,4,5)))\n"
    "expect(chost.sum(1,2,3,4,5) == 15, 'variadic C function sums integer args')\n"
    "local ok2, err2 = pcall(chost.sum, 1, 'x')\n"
    "expect(not ok2 and tostring(err2):match('number expected') ~= nil,\n"
    "       'luaL_checkinteger raises on a non-numeric argument')\n"
    "local oke, errE = pcall(chost.sum_checked, 'x', 2)\n"
    "expect(not oke and tostring(errE):match('argument #1 must be') ~= nil,\n"
    "       'luaL_error produces the message written by our own C code')\n"
    "\n"
    "-- 5.3+ subtypes: luaL_checkinteger refuses a float with no integer\n"
    "-- representation, while older Lua truncates it. Measure, do not guess.\n"
    "local okf, errf = pcall(chost.sum, 1.5, 2.5)\n"
    "if LUA_VERSION_NUM >= 503 then\n"
    "  expect(not okf and tostring(errf):match('integer representation') ~= nil,\n"
    "         '5.3+: luaL_checkinteger rejects 1.5 (no integer representation)')\n"
    "else\n"
    "  expect(okf and errf == 3, 'pre-5.3: luaL_checkinteger truncates 1.5 to 1')\n"
    "end\n"
    "expect(chost.sum(2.0, 4.0) == 6, 'an integral float is accepted as an integer')\n"
    "\n"
    "-- 3. binary-safe strings\n"
    "local embedded = 'ab\\0cd'\n"
    "local n1, n2 = chost.strlen(embedded)\n"
    "emit(string.format('LEN=%d CSTRLEN=%d', n1, n2))\n"
    "expect(n1 == 5, 'luaL_checklstring reports the real byte length')\n"
    "expect(n2 == 2, 'strlen() stops at the embedded NUL -- the classic mismatch')\n"
    "expect(chost.has_embedded_nul(embedded) == true, 'the mismatch is detectable')\n"
    "local oknum, rn1, rn2 = pcall(chost.strlen, 42)\n"
    "expect(oknum and rn1 == 2, 'a number is accepted where a string is expected')\n"
    "expect(not pcall(chost.strlen, {}), 'a table is rejected with an error')\n"
    "\n"
    "-- 4. tables\n"
    "local t = {10, 20, 30, 40}\n"
    "local total, n = chost.table_sum(t)\n"
    "emit(string.format('TABLE_SUM=%d SLOTS=%d', total, n))\n"
    "expect(total == 100 and n == 4, 'rawlen + rawgeti walk a dense sequence')\n"
    "expect(chost.table_keys({a=1, b=2, 9}) == 3, 'lua_next counts every key')\n"
    "expect(not pcall(chost.table_sum, 'nope'), 'luaL_checktype rejects a non-table')\n"
    "\n"
    "-- 5. userdata + metatable\n"
    "local p = chost.new_point(3, 4)\n"
    "emit(tostring(p))\n"
    "expect(math.abs(#p - 5) < 1e-9, '__len computes the magnitude')\n"
    "expect(p.x == 3 and p.kind == 'point', '__index serves fields')\n"
    "expect(tostring(p):find('point(', 1, true) == 1,\n"
    "       '__tostring is dispatched instead of the default userdata: 0x...')\n"
    "expect(chost.point_dot(p, chost.new_point(1, 1)) == 7,\n"
    "       'C method on userdata computes the dot product (3,4) . (1,1) = 7')\n"
    "expect(not pcall(function() return p.z end), 'unknown field raises an error')\n"
    "expect(not pcall(chost.point_dot, p, 'nope'),\n"
    "       'luaL_checkudata rejects the wrong userdata type')\n"
    "\n"
    "-- 6. errors crossing the boundary\n"
    "expect(not pcall(chost.fail), 'an error raised by C is caught by pcall')\n"
    "local okd, errd = pcall(chost.div, 10, 0)\n"
    "expect(not okd and tostring(errd):match('division by zero') ~= nil,\n"
    "       'luaL_error carries formatted context')\n"
    "expect(chost.div(9, 3) == 3, 'the non-error path still works')\n"
    "\n"
    "-- 7. registry storage invisible to ordinary Lua\n"
    "chost.cache_put('greeting', 'hello from C')\n"
    "expect(chost.cache_get('greeting') == 'hello from C', 'registry round-trip')\n"
    "local miss, why = chost.cache_get('absent')\n"
    "expect(miss == nil and why == 'not cached', 'a registry miss reports nil + reason')\n"
    "\n"
    "emit(string.format('LUA_FAILURES=%d', fails))\n"
    "return table.concat(out, '\\n')\n");

  if (status != LUA_OK) {
    printf("FATAL: %s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  /* Run the chunk under lua_pcall: this is what a host must do, never lua_call,
   * because lua_call cannot catch a Lua error on the C side. */
  if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
    printf("FATAL: pcall failed: %s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  printf("%s\n", lua_tostring(L, -1));
  lua_settop(L, 0);

  printf("HOST_FAILURES=%d\n", failures);
  lua_close(L);
  return failures == 0 ? 0 : 1;
}
