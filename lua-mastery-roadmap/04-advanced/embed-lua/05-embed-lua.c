/*
 * Project 5: Embedding Lua in a C Host
 * Stage: D (Internals and Native Integration)
 * Difficulty: Advanced
 * Lua Version: 5.3+ / 5.4
 *
 * Demonstrates: C API stack discipline, userdata with metatables,
 *               error handling across Lua/C boundary, host API registration
 *
 * Build (Linux): gcc -o embed_lua 05-embed-lua.c -llua -lm -ldl
 * Build (macOS): gcc -o embed_lua 05-embed-lua.c -llua -lm
 * Run:           ./embed_lua
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/* ============================================================
 * Host-side API functions exposed to Lua
 * ============================================================ */

/* host.log(level, message) — structured logging */
static int l_host_log(lua_State *L) {
    const char *level = luaL_checkstring(L, 1);
    const char *msg   = luaL_checkstring(L, 2);
    printf("[%s] %s\n", level, msg);
    return 0;
}

/* host.time() — host monotonic clock */
static int l_host_time(lua_State *L) {
    lua_pushnumber(L, (lua_Number)clock() / CLOCKS_PER_SEC);
    return 1;
}

/* host.malloc(size) — demonstrate pointer return */
static int l_host_malloc(lua_State *L) {
    size_t size = (size_t)luaL_checkinteger(L, 1);
    void *ptr = malloc(size);
    if (!ptr) {
        lua_pushnil(L);
        lua_pushstring(L, "allocation failed");
        return 2;
    }
    lua_pushlightuserdata(L, ptr);
    return 1;
}

/* host.free(ptr) — free lightuserdata */
static int l_host_free(lua_State *L) {
    void *ptr = lua_touserdata(L, 1);
    if (ptr) free(ptr);
    return 0;
}

/* ============================================================
 * Counter userdata with metatable
 * ============================================================ */

typedef struct {
    int value;
} Counter;

static int l_counter_new(lua_State *L) {
    lua_Integer init = luaL_optinteger(L, 1, 0);
    Counter *c = (Counter *)lua_newuserdata(L, sizeof(Counter));
    c->value = (int)init;
    luaL_setmetatable(L, "Counter");
    return 1;
}

static int l_counter_inc(lua_State *L) {
    Counter *c = (Counter *)luaL_checkudata(L, 1, "Counter");
    lua_Integer step = luaL_optinteger(L, 2, 1);
    c->value += (int)step;
    lua_pushinteger(L, c->value);
    return 1;
}

static int l_counter_get(lua_State *L) {
    Counter *c = (Counter *)luaL_checkudata(L, 1, "Counter");
    lua_pushinteger(L, c->value);
    return 1;
}

static int l_counter_tostring(lua_State *L) {
    Counter *c = (Counter *)luaL_checkudata(L, 1, "Counter");
    lua_pushfstring(L, "Counter(%d)", c->value);
    return 1;
}

static void register_counter_metatable(lua_State *L) {
    luaL_newmetatable(L, "Counter");

    lua_pushcfunction(L, l_counter_tostring);
    lua_setfield(L, -2, "__tostring");

    lua_pushcfunction(L, l_counter_inc);
    lua_setfield(L, -2, "__call");

    luaL_Reg methods[] = {
        {"inc", l_counter_inc},
        {"get", l_counter_get},
        {NULL, NULL}
    };
    luaL_setfuncs(L, methods, 0);

    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");

    lua_pop(L, 1);
}

/* ============================================================
 * Register all host API into Lua
 * ============================================================ */

static void register_host_api(lua_State *L) {
    /* Create host table */
    lua_newtable(L);

    lua_pushcfunction(L, l_host_log);
    lua_setfield(L, -2, "log");

    lua_pushcfunction(L, l_host_time);
    lua_setfield(L, -2, "time");

    lua_pushcfunction(L, l_host_malloc);
    lua_setfield(L, -2, "malloc");

    lua_pushcfunction(L, l_host_free);
    lua_setfield(L, -2, "free");

    lua_pushcfunction(L, l_counter_new);
    lua_setfield(L, -2, "Counter");

    lua_setglobal(L, "host");
}

/* ============================================================
 * Main
 * ============================================================ */

int main(void) {
    lua_State *L = luaL_newstate();
    if (!L) {
        fprintf(stderr, "Failed to create Lua state\n");
        return 1;
    }

    luaL_openlibs(L);
    register_counter_metatable(L);
    register_host_api(L);

    /* Lua script demonstrating host embedding */
    const char *script =
        "host.log('INFO', 'Lua script started')\n"
        "\n"
        "-- Use host counter userdata\n"
        "local c = host.Counter(10)\n"
        "c:inc(5)\n"
        "host.log('INFO', 'Counter value: ' .. tostring(c))\n"
        "host.log('INFO', 'Counter get: ' .. c:get())\n"
        "\n"
        "-- Use host time\n"
        "local t = host.time()\n"
        "host.log('INFO', string.format('Host time: %.6f', t))\n"
        "\n"
        "-- Test error handling across boundary\n"
        "local ok, err = pcall(function()\n"
        "  error('deliberate error from Lua')\n"
        "end)\n"
        "if not ok then\n"
        "  host.log('WARN', 'Caught error: ' .. tostring(err))\n"
        "end\n"
        "\n"
        "-- Test type validation\n"
        "local ok2, err2 = pcall(function()\n"
        "  host.Counter('not a number')\n"
        "end)\n"
        "if not ok2 then\n"
        "  host.log('WARN', 'Type check: ' .. tostring(err2))\n"
        "end\n"
        "\n"
        "host.log('INFO', 'Script completed successfully')\n";

    printf("=== Lua Embed Demo ===\n\n");

    if (luaL_dostring(L, script) != LUA_OK) {
        fprintf(stderr, "Script error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    printf("\n=== Done ===\n");

    lua_close(L);
    return 0;
}
