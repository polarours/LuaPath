# Interoperability Patterns

> **Phase**: Cross-cutting
> **Prerequisites**: Chapter 11 — The Lua C API, Chapter 17 — Embedding Patterns
> **Time Estimate**: 3–4 hours
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (C API varies by version)

---

## What Is Interoperability?

Interoperability means Lua code communicating with programs written in other languages — most commonly C, because the Lua C API is the canonical and most performant way to extend Lua. Beyond C, bindings exist for C++, Rust, Go, Python, Java, and others, but they all share the same fundamental patterns:

1. **Embedding**: Your program hosts a Lua interpreter and runs Lua scripts
2. **Extending**: Lua calls into native code (C, Rust, etc.)
3. **Bidirectional**: Both directions combined

---

## The C API as the Foundation

The Lua C API is a set of C functions that let you:
- Create and destroy Lua states
- Read and write Lua values
- Call Lua functions from C
- Register C functions callable from Lua

```c
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(int argc, char *argv[]) {
    lua_State *L = luaL_newstate();      // create state
    luaL_openlibs(L);                   // open standard libraries

    // Run a Lua script
    if (luaL_dofile(L, "script.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    lua_close(L);
    return 0;
}
```

---

## Registering C Functions to Lua

### The Basic Pattern

Every C function exposed to Lua has the same signature:

```c
// Must match: int (*lua_CFunction)(lua_State *L)
static int l_my_function(lua_State *L) {
    // Read arguments: luaL_checknumber, luaL_checkstring, etc.
    double x = luaL_checknumber(L, 1);
    double y = luaL_checknumber(L, 2);

    // Do the work
    double result = x + y;

    // Push the result(s) onto the stack
    lua_pushnumber(L, result);

    // Number of results (Lua can have multiple return values)
    return 1;
}
```

Register it with:

```c
static const luaL_Reg mylib[] = {
    { "my_function", l_my_function },
    { NULL, NULL }  // sentinel
};

// Call once during module initialization
luaL_newlib(L, mylib);  // Lua 5.2+
lua_setglobal(L, "mylib");
```

```lua
-- Now callable from Lua
local r = mylib.my_function(3, 4)  -- r = 7
```

### Error Handling

C functions can raise Lua errors:

```c
static int l_div(lua_State *L) {
    double a = luaL_checknumber(L, 1);
    double b = luaL_checknumber(L, 2);
    if (b == 0) {
        return luaL_error(L, "division by zero");
    }
    lua_pushnumber(L, a / b);
    return 1;
}
```

```lua
local ok, err = pcall(mylib.div, 1, 0)
-- ok = false, err = "division by zero"
```

---

## Calling Lua from C

### Calling a Lua Function

```c
void call_lua_function(lua_State *L, double x) {
    // Push the function onto the stack
    lua_getglobal(L, "my_lua_callback");

    // Push the arguments
    lua_pushnumber(L, x);

    // Call: 1 argument, 1 result, 0 in errfunc
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        fprintf(stderr, "Lua error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        return;
    }

    // Get the result
    double result = lua_tonumber(L, -1);
    lua_pop(L, 1);  // pop the result

    printf("Result: %f\n", result);
}
```

```lua
-- Lua side
function my_lua_callback(x)
    return x * x
end
```

### Lua Tables to C Structs

Passing structured data between Lua and C requires converting to/from tables:

```c
// C: read a table as a key-value options object
static int l_configure(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);

    // Read fields
    const char *host = NULL;
    int port = 0;

    lua_getfield(L, 1, "host");
    if (!lua_isnil(L, -1)) host = luaL_checkstring(L, -1);
    lua_pop(L, 1);

    lua_getfield(L, 1, "port");
    if (!lua_isnil(L, -1)) port = luaL_checkinteger(L, -1);
    lua_pop(L, 1);

    printf("Connecting to %s:%d\n", host ? host : "localhost", port);
    return 0;
}
```

```lua
mylib.configure { host = "api.example.com", port = 8080 }
```

---

## Userdata and Metatables

Userdata lets C attach structured data to Lua values that the Lua side cannot forge:

```c
// Counter userdata with private state
typedef struct {
    int value;
} Counter;

static int l_counter_new(lua_State *L) {
    Counter *c = (Counter *)lua_newuserdata(L, sizeof(Counter));
    c->value = (int)luaL_optinteger(L, 1, 0);

    // Set metatable on the userdata
    luaL_getmetatable(L, "Counter");
    lua_setmetatable(L, -2);
    return 1;  // userdata is already on the stack
}

static int l_counter_inc(lua_State *L) {
    Counter *c = (Counter *)luaL_checkudata(L, 1, "Counter");
    int delta = (int)luaL_optinteger(L, 2, 1);
    c->value += delta;
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

static const luaL_Reg Counter_methods[] = {
    { "inc",   l_counter_inc   },
    { "get",   l_counter_get   },
    { "__tostring", l_counter_tostring },
    { "__call", l_counter_inc },   // allow counter() as shorthand
    { NULL, NULL }
};

// Registration
static const luaL_Reg Counter_functions[] = {
    { "new", l_counter_new },
    { NULL, NULL }
};
```

```lua
local c = mylib.Counter.new(10)
print(c:get())    -- 10
c:inc(5)          -- 15
c(3)              -- 18  (via __call)
print(tostring(c)) -- Counter(18)
```

---

## Lua/C Data Conversion

### Automatic Conversion Patterns

```c
// Iterate a Lua table from C
static int l_table_sum(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    double sum = 0;

    lua_pushnil(L);  // first key
    while (lua_next(L, 1) != 0) {
        // stack: ... key value
        if (lua_isnumber(L, -1)) {
            sum += lua_tonumber(L, -1);
        }
        lua_pop(L, 1);  // remove value, keep key for next iteration
    }

    lua_pushnumber(L, sum);
    return 1;
}
```

```lua
local total = mylib.table_sum { 1, 2, 3, 4, 5 }  -- 15
```

### String Buffers

C code can build strings efficiently with `luaL_Buffer`:

```c
static int l_join(lua_State *L) {
    const char *sep = luaL_checkstring(L, 1);
    luaL_checktype(L, 2, LUA_TTABLE);

    luaL_Buffer b;
    luaL_buffinit(L, &b);

    int first = 1;
    lua_pushnil(L);
    while (lua_next(L, 2)) {
        if (!first) luaL_addstring(&b, sep);
        first = 0;
        luaL_addvalue(&b);  // add value at top to buffer
        lua_pop(L, 1);
    }
    luaL_pushresult(&b);
    return 1;
}
```

```lua
local joined = mylib.join(", ", {"a", "b", "c"})  -- "a, b, c"
```

---

## Coroutines across the C/Lua Boundary

Suspended Lua coroutines can be paused from C and resumed later:

```c
// Resume a coroutine from C, giving it a value
static int l_resume_with(lua_State *L) {
    lua_State *co = *(lua_State **)luaL_checkudata(L, 1, "LuaThread");
    lua_xmove(L, co, 1);  // move argument to coroutine's stack

    int status = lua_resume(co, L, 1);  // 1 argument
    if (status == LUA_YIELD) {
        lua_pushboolean(L, 1);
        lua_pushstring(L, "resumed");
        return 2;
    } else if (status == LUA_OK) {
        lua_pushboolean(L, 0);
        lua_pushstring(L, "finished");
        return 2;
    } else {
        lua_pushboolean(L, 0);
        lua_pushstring(L, lua_tostring(co, -1));
        return 2;
    }
}
```

---

## Async and Thread Patterns

### Native Threads Calling Lua

C threads can run Lua code independently:

```c
// Spawn a Lua thread from C
static int l_spawn_thread(lua_State *L) {
    lua_State *co = lua_newthread(L);  // pushed onto parent's stack

    // Load a Lua function
    lua_getglobal(co, "worker");
    if (lua_type(co, -1) != LUA_TFUNCTION) {
        return luaL_error(L, "global 'worker' must be a function");
    }

    // Resume with initial value
    lua_pushstring(co, "start");
    int status = lua_resume(co, L, 1);
    if (status == LUA_YIELD) {
        printf("Thread yielded: %s\n", lua_tostring(co, -1));
    }

    return 1;  // return the thread
}
```

---

## Memory Management across the Boundary

Lua's garbage collector does not trace through C-allocated memory by default. Use the following patterns:

### Tying the Lifetimes Together

If C allocates memory that Lua must eventually free, store a finalizer:

```c
// When creating userdata with C-managed memory:
static int l_alloc_buffer(lua_State *L) {
    size_t size = (size_t)luaL_checkinteger(L, 1);
    Buffer *buf = (Buffer *)lua_newuserdata(L, sizeof(Buffer));
    buf->data = malloc(size);
    buf->size = size;

    // Set finalizer: called when GC collects this userdata
    lua_createtable(L, 0, 1);
    lua_pushcfunction(L, l_buffer_gc);
    lua_setfield(L, -2, "__gc");
    lua_setmetatable(L, -2);
    return 1;
}

static int l_buffer_gc(lua_State *L) {
    Buffer *buf = (Buffer *)luaL_checkudata(L, 1, "Buffer");
    free(buf->data);
    return 0;
}
```

### Weak Tables for C Object References

If Lua needs to hold references to C objects without preventing GC:

```lua
-- Lua side: store in a weak table
local refs = setmetatable({}, { __mode = "v" })

function register(obj)
    local handle = next_handle()
    refs[handle] = obj  -- weak reference
    return handle
end
```

---

## Best Practices

### Error Conventions

Choose one policy and be consistent:

| Policy | Lua errors | C errors |
|--------|-----------|----------|
| **Propagate** | `lua_error` / `luaL_error` | return error string from C function |
| **Return nil+error** | `return nil, "message"` | `lua_pushnil(L); lua_pushstring(L, err); return 2` |

```c
// Prefer: return nil + error message
static int l_may_fail(lua_State *L) {
    if (some_condition) {
        lua_pushnil(L);
        lua_pushstring(L, "condition not met");
        return 2;
    }
    lua_pushboolean(L, 1);
    return 1;
}
```

```lua
local ok, err = pcall(mylib.may_fail)
-- or
local ok, err = mylib.may_fail()
if not ok then print(err) end
```

### API Version Detection

Check Lua version at compile time:

```c
#if LUA_VERSION_NUM >= 502
    #define lua_rawlen lua_rawlen
#else
    #define lua_rawlen lua_objlen
#endif

#if LUA_VERSION_NUM >= 503
    #define lua_integer lua_Integer
#else
    #define lua_integer int
#endif
```

### Naming Conventions

- C functions: `l_<module>_<name>`
- Userdata metatables: `<Module>.<Name>`
- Constants: `LUA_<CONSTANT>` style

### Thread Safety

**Never** call Lua functions from multiple C threads without synchronization. A `lua_State` is not thread-safe. If you need concurrent Lua execution, create one `lua_State` per OS thread.

---

## Exercises

1. **Register a C module**: Write a C module that exposes `math_extra.gcd(a, b)` and `math_extra.lcm(a, b)` using the Lua C API. Test it from Lua.

2. **Userdata with metatable**: Implement a `Vector` userdata (x, y, z) with `__add`, `__mul`, and `__len` metamethods from C.

3. **Bidirectional bridge**: Implement a C function that receives a Lua callback, stores it in a registry, and calls it back from a separate C function.

4. **Table-to-struct converter**: Write a C function that accepts a Lua table with fields `{host, port, timeout}` and prints them, handling missing fields gracefully.

---

## Key Takeaways

- **The Lua C API is stack-based**: All communication between Lua and C happens through a virtual stack.
- **Userdata + metatable = opaque objects**: This is the safe way to expose C structs to Lua.
- **Propagate errors up**: Either use `luaL_error()` or return `nil, err` — never silently swallow errors.
- **Tie lifetimes explicitly**: If C allocates memory that Lua manages, use `__gc` finalizers.
- **One state per thread**: `lua_State` is not thread-safe; use one per OS thread.
- **Prefer embedding over raw C API when possible**: If you need Lua-C interop for a non-C language, look for an existing binding library first.
