# 11 — Lua C API

> **Phase**: D (Internals and Native Integration)  
> **Prerequisites**: Chapter 10 — Lua Internals  
> **Time Estimate**: 3–4 hours reading + 4–6 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Understand the C API stack discipline** — push, pop, and index values correctly
2. **Write C functions** that integrate with Lua safely
3. **Bind C data structures** to Lua using userdata and metatables
4. **Handle errors across the Lua/C boundary** without crashing
5. **Embed Lua** in a C host application with proper lifecycle management

---

## Stack Protocol

The C API is a **strict stack protocol**. All data exchange between C and Lua happens through a virtual stack.

### Basic Stack Operations

```c
#include <lua.h>
#include <lauxlib.h>

// Push values onto the stack
lua_pushnumber(L, 3.14);      // Push number
lua_pushstring(L, "hello");   // Push string
lua_pushboolean(L, 1);        // Push boolean
lua_pushnil(L);               // Push nil
lua_pushcfunction(L, my_func);// Push C function

// Pop values from the stack
lua_pop(L, 1);                // Pop 1 value
lua_pop(L, 3);                // Pop 3 values

// Get stack size
int top = lua_gettop(L);
```

### Indexing

```c
// Positive index: from bottom (1 = first argument)
lua_pushnumber(L, 10);    // Stack: [10]
lua_pushnumber(L, 20);    // Stack: [10, 20]
lua_pushnumber(L, 30);    // Stack: [10, 20, 30]

lua_tonumber(L, 1);  // 10.0 (first element)
lua_tonumber(L, 2);  // 20.0 (second element)
lua_tonumber(L, 3);  // 30.0 (third element, top)

// Negative index: from top (-1 = top)
lua_tonumber(L, -1); // 30.0 (top)
lua_tonumber(L, -2); // 20.0
lua_tonumber(L, -3); // 10.0 (bottom)
```

### Type Checking

```c
// Check type
int type = lua_type(L, 1);
switch (type) {
    case LUA_TNIL:      break;
    case LUA_TBOOLEAN:  break;
    case LUA_TNUMBER:   break;
    case LUA_TSTRING:   break;
    case LUA_TTABLE:    break;
    case LUA_TFUNCTION: break;
    case LUA_TUSERDATA: break;
    // ...
}

// Type name
const char *name = lua_typename(L, type);  // "number", "string", etc.
```

---

## Writing C Functions

A C function callable from Lua must have this signature:

```c
int function_name(lua_State *L);
```

The return value is the **number of return values** pushed onto the stack.

### Simple Function

```c
static int l_add(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);  // First arg
    lua_Number b = luaL_checknumber(L, 2);  // Second arg
    lua_pushnumber(L, a + b);               // Push result
    return 1;                               // 1 return value
}

// Register with Lua
lua_pushcfunction(L, l_add);
lua_setglobal(L, "add");
```

### Multiple Return Values

```c
static int l_divmod(lua_State *L) {
    lua_Integer a = luaL_checkinteger(L, 1);
    lua_Integer b = luaL_checkinteger(L, 2);
    if (b == 0) {
        lua_pushnil(L);
        lua_pushstring(L, "division by zero");
        return 2;  // 2 return values
    }
    lua_pushinteger(L, a / b);  // quotient
    lua_pushinteger(L, a % b);  // remainder
    return 2;
}
```

### Argument Validation

```c
// Check and throw on bad input
luaL_checknumber(L, 1);    // Throws if arg 1 is not a number
luaL_checkstring(L, 2);    // Throws if arg 2 is not a string
luaL_checktype(L, 3, LUA_TTABLE);  // Throws if arg 3 is not a table

// Optional arguments with defaults
lua_Integer n = luaL_optinteger(L, 1, 10);  // Default 10
const char *s = luaL_optstring(L, 2, "default");
```

---

## String Handling

### Pushing Strings

```c
// Push a C string
lua_pushstring(L, "hello");

// Push with explicit length
lua_pushlstring(L, "hello", 5);

// Push formatted string
lua_pushfstring(L, "Value: %d", 42);
```

### Getting Strings

```c
// Get string (may be modified by GC after stack changes)
const char *s = lua_tostring(L, 1);

// Get string with length
size_t len;
const char *s = lua_tolstring(L, 1, &len);

// Check string (throws if not string)
const char *s = luaL_checkstring(L, 1);
```

> **Warning**: `lua_tostring` returns a pointer to the internal string. This pointer may become invalid after any C API call that modifies the stack or triggers GC. Copy the string immediately if you need it later.

---

## Table Operations

```c
// Create a new table
lua_newtable(L);

// Set field: t[key] = value
lua_pushstring(L, "name");
lua_pushstring(L, "Lua");
lua_settable(L, -3);  // Sets t["name"] = "Lua"

// Get field: value = t[key]
lua_pushstring(L, "name");
lua_gettable(L, -2);  // Pushes t["name"]

// Array-style: t[i] = value
lua_pushinteger(L, 1);
lua_pushstring(L, "first");
lua_rawseti(L, -2, 1);  // t[1] = "first"

// Raw access (bypass metamethods)
lua_rawgeti(L, 1, 2);   // Get t[2] without __index
lua_rawseti(L, 1, 2);   // Set t[2] without __newindex
```

---

## Userdata

Userdata allows C data to be managed by Lua's garbage collector.

### Light Userdata

```c
// Pointer-sized, not GC-managed
void *ptr = malloc(100);
lua_pushlightuserdata(L, ptr);
// Caller is responsible for freeing ptr
```

### Full Userdata

```c
// GC-managed block of memory
void *ud = lua_newuserdata(L, 100);  // Allocates 100 bytes
// ud is now on the stack as userdata
// Lua will free this memory when no longer referenced

// Attach metatable for behavior
luaL_getmetatable(L, "MyType");
lua_setmetatable(L, -2);
```

### Binding a C Struct

```c
typedef struct {
    double x;
    double y;
} Point;

static int l_point_new(lua_State *L) {
    lua_Number x = luaL_checknumber(L, 1);
    lua_Number y = luaL_checknumber(L, 2);
    Point *p = (Point *)lua_newuserdata(L, sizeof(Point));
    p->x = x;
    p->y = y;
    luaL_getmetatable(L, "Point");
    lua_setmetatable(L, -2);
    return 1;
}

static int l_point_distance(lua_State *L) {
    Point *a = (Point *)luaL_checkudata(L, 1, "Point");
    Point *b = (Point *)luaL_checkudata(L, 2, "Point");
    double dx = a->x - b->x;
    double dy = a->y - b->y;
    lua_pushnumber(L, sqrt(dx*dx + dy*dy));
    return 1;
}
```

### Metatable for Userdata

```c
// Create metatable
luaL_newmetatable(L, "Point");

// Add methods
luaL_Reg methods[] = {
    {"distance", l_point_distance},
    {NULL, NULL}
};
luaL_setfuncs(L, methods, 0);

// Add __index to point to methods table
lua_pushvalue(L, -1);           // Copy metatable
lua_setfield(L, -2, "__index"); // metatable.__index = metatable

lua_pop(L, 1);  // Pop metatable
```

---

## Error Handling

### Protected C Calls

```c
// lua_pcall catches errors
if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    const char *err = lua_tostring(L, -1);
    fprintf(stderr, "Error: %s\n", err);
    lua_pop(L, 1);
}
```

### Throwing Errors from C

```c
// Push error message and longjmp
luaL_error(L, "invalid argument: %s", msg);

// Or push error manually
lua_pushnil(L);
lua_pushfstring(L, "error: %s", msg);
return 2;
```

### Error Across C Boundary

```c
// NEVER use C longjmp/exceptions across Lua boundary
// Use lua_pcall to protect calls into Lua
// Use lua_error (which does longjmp) to propagate errors

// WRONG: C exception across Lua
// try { lua_call(L, ...); } catch (...) { /* crashes! */ }

// RIGHT: Protected call
int status = lua_pcall(L, nargs, nresults, 0);
if (status != LUA_OK) {
    // Handle error safely
}
```

---

## Registry

The **registry** is a hidden table for storing C-side data:

```c
// Store value with unique key
lua_pushvalue(L, 1);                    // Value to store
int ref = luaL_ref(L, LUA_REGISTRYINDEX); // Get unique integer key
// ref is now a unique ID

// Retrieve value
lua_rawgeti(L, LUA_REGISTRYINDEX, ref);  // Push stored value

// Remove reference
luaL_unref(L, LUA_REGISTRYINDEX, ref);
```

### Named References

```c
// Store with string key (easier to debug)
lua_pushvalue(L, 1);
lua_setfield(L, LUA_REGISTRYINDEX, "my_object");

// Retrieve
lua_getfield(L, LUA_REGISTRYINDEX, "my_object");
```

---

## Minimal Embedding Workflow

```c
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(void) {
    // 1. Create state
    lua_State *L = luaL_newstate();
    if (!L) { fprintf(stderr, "Cannot create Lua state\n"); return 1; }

    // 2. Open standard libraries
    luaL_openlibs(L);

    // 3. Register C functions
    lua_pushcfunction(L, l_add);
    lua_setglobal(L, "host_add");

    // 4. Load and run script
    if (luaL_dostring(L, "print(host_add(2, 3))") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    // 5. Close state
    lua_close(L);
    return 0;
}
```

---

## Common Pitfalls

### 1. Returning Wrong Number of Values

```c
// BUG: Said 2 returns, only pushed 1
lua_pushnumber(L, 42);
return 2;  // Second value is garbage!

// FIX: Push all values before returning
lua_pushnumber(L, 42);
lua_pushstring(L, "ok");
return 2;
```

### 2. Using Stale Pointers

```c
// BUG: String pointer becomes invalid
const char *s = lua_tostring(L, 1);
lua_pushnumber(L, 42);  // May trigger GC!
// s is now potentially invalid

// FIX: Copy the string
const char *s = lua_tostring(L, 1);
char *copy = strdup(s);
// Use copy, then free(copy)
```

### 3. Stack Imbalance

```c
// BUG: Pushes without popping
static int bad_func(lua_State *L) {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 2);
    lua_pushnumber(L, 3);
    return 1;  // 2 values leaked on stack!
}

// FIX: Use lua_settop or be precise
static int good_func(lua_State *L) {
    lua_pushnumber(L, 1);
    lua_pushnumber(L, 2);
    lua_pushnumber(L, 3);
    lua_settop(L, -2);  // Keep only top value
    return 1;
}
```

### 4. Not Checking Argument Types

```c
// BUG: Assumes argument is number
static int bad_func(lua_State *L) {
    double x = lua_tonumber(L, 1);  // 0.0 if not a number!
    return 1;
}

// FIX: Use luaL_check* functions
static int good_func(lua_State *L) {
    double x = luaL_checknumber(L, 1);  // Throws if not number
    lua_pushnumber(L, x * 2);
    return 1;
}
```

### 5. Forgetting to Set Metatable

```c
// BUG: Userdata has no methods
Point *p = lua_newuserdata(L, sizeof(Point));
// No metatable set — can't call methods!

// FIX: Always set metatable for userdata
luaL_getmetatable(L, "Point");
lua_setmetatable(L, -2);
```

---

## Best Practices

### 1. Use luaL_check* for Validation

```c
// Always validate arguments
luaL_checknumber(L, 1);
luaL_checkstring(L, 2);
luaL_checktype(L, 3, LUA_TTABLE);
luaL_checkudata(L, 4, "Point");
```

### 2. Use Registry for Stable References

```c
// Store callbacks/data in registry, not on stack
int ref = luaL_ref(L, LUA_REGISTRYINDEX);
// ref survives across C calls
```

### 3. Protect Against Untrusted Scripts

```c
// Use lua_pcall for any script execution
if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    const char *err = lua_tostring(L, -1);
    log_error(err);
    lua_pop(L, 1);
}
```

### 4. Document Stack State

```c
// Before: stack = [arg1, arg2]
static int my_func(lua_State *L) {
    // Stack: [arg1, arg2]
    lua_pushnumber(L, 42);
    // Stack: [arg1, arg2, 42]
    return 1;
    // Stack after return: [42]
}
```

### 5. Clean Up on Error Paths

```c
static int risky_func(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    // ... do work ...
    if (error_condition) {
        luaL_unref(L, LUA_REGISTRYINDEX, ref);  // Cleanup!
        return luaL_error(L, "something went wrong");
    }
    // ...
}
```

---

## Version Notes

### Lua 5.1

- `luaL_check*` functions available
- `lua_newuserdata` available
- `lua_pcall` with error handler function (4th arg)

### Lua 5.2/5.3

- `luaL_setfuncs` replaces `luaL_register`
- `luaL_newlib` / `luaL_newmetatable` helpers
- `lua_rawlen` for raw length (replaces `lua_objlen`)

### Lua 5.4

- `lua_newuserdatauv` for userdata with user values
- `lua_resetthread` for coroutine reset
- `luaL_loadbufferx` with mode parameter
- Improved error messages

### LuaJIT

- FFI library for direct C function calls without wrappers
- `ffi.cdef` for C type declarations
- `ffi.cast` for type conversions
- Performance is excellent for C interop

---

## Knowledge Check

<details>
<summary>1. What happens if you push 3 values but return 2?</summary>

The third value remains on the stack, causing a stack leak. Over many calls, this can overflow the stack. Always ensure pushed values match the return count.
</details>

<details>
<summary>2. Why must you use <code>luaL_check*</code> instead of <code>lua_to*</code>?</summary>

`lua_to*` returns a default value (0, NULL) if the argument is the wrong type, silently causing bugs. `luaL_check*` throws a Lua error, making type mismatches visible immediately.
</details>

<details>
<summary>3. What is the registry, and why use it?</summary>

The registry is a hidden table in `LUA_REGISTRYINDEX` for storing C-side data. It's accessible from any C function in the state, providing a stable place to store callbacks, userdata references, and other persistent data.
</details>

<details>
<summary>4. Why is <code>lua_pcall</code> safer than <code>lua_call</code>?</summary>

`lua_call` does a longjmp on error, which can skip C cleanup code and crash. `lua_pcall` catches errors and returns a status code, allowing safe cleanup.
</details>

<details>
<summary>5. What's the difference between light and full userdata?</summary>

Light userdata is just a pointer — Lua doesn't manage its memory. Full userdata is a Lua-managed memory block with GC, metatable support, and proper lifecycle management.
</details>

---

## Key Takeaways

- **Stack protocol**: all data exchange via push/pop/index
- **C functions**: return number of values pushed
- **`luaL_check*`**: always validate arguments (don't use `lua_to*`)
- **Userdata**: bind C data to Lua with GC and metatables
- **Registry**: stable storage for C-side references
- **`lua_pcall`**: safe error handling across Lua/C boundary
- **Never use C exceptions** across Lua boundary
- **Document stack state** at every function entry/exit

---

## Exercises

### Beginner (30–60 min)

1. **Host Clock**: Expose `os.clock()` as a C function `host_monotonic()` returning a high-resolution timer.

2. **String Concat**: Write a C function that concatenates N string arguments.

3. **Table Builder**: Create a C function `make_table(k1, v1, k2, v2, ...)` that builds a Lua table from alternating key-value pairs.

### Intermediate (1–2 hours)

4. **Point Bindings**: Implement full Point userdata with `new(x,y)`, `add(other)`, `distance(other)`, and `__tostring`.

5. **Array Bindings**: Create a C-backed array type with `get(i)`, `set(i, v)`, `length()`, and `__index`/`__newindex` metamethods.

6. **Error Reporter**: Write a C function that calls a Lua callback and properly handles errors with stack traces.

### Advanced (2–4 hours)

7. **Module Loader**: Implement a C module that registers itself with `require("mymod")` and provides multiple functions.

8. **Embedding Framework**: Build a minimal embedding framework with `init()`, `load_script()`, `call_function()`, and `shutdown()` lifecycle.

---

## Example Code

Runnable examples for this chapter:
- `examples/advanced/01-ecs-system.lua` — Uses userdata-like patterns
- `examples/projects/` — Target for embedding projects

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 4](https://www.lua.org/manual/5.4/manual.html#4)
- [Programming in Lua (4th ed.) — Chapter 28–29](https://www.lua.org/pil/)
- [Next Chapter: 12 — Performance](12-performance.md)
