# 11 — Lua C API

> **阶段**: D（内部机制与原生集成）
> **前置知识**: 第 10 章 — Lua 内部机制
> **预估时间**: 3–4 小时阅读 + 4–6 小时练习
> **Lua 版本**: 5.1、5.3、5.4、LuaJIT（差异有标注）

---

## 学习目标

完成本章后，你将能够：

1. **理解 C API 栈协议** — 正确地压入、弹出和索引值
2. **编写安全集成到 Lua 中的 C 函数**
3. **使用 userdata 和 metatable 将 C 数据结构绑定到 Lua**
4. **跨 Lua/C 边界处理错误**而不崩溃
5. **在 C 宿主应用程序中嵌入 Lua**并正确管理生命周期

---

## 栈协议

C API 是一个**严格的栈协议**。C 和 Lua 之间的所有数据交换都通过一个虚拟栈完成。

### 基本栈操作

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

### 索引

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

### 类型检查

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

## 编写 C 函数

可以从 Lua 调用的 C 函数必须具有以下签名：

```c
int function_name(lua_State *L);
```

返回值是压入栈中的**返回值的数量**。

### 简单函数

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

### 多返回值

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

### 参数验证

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

## 字符串处理

### 压入字符串

```c
// Push a C string
lua_pushstring(L, "hello");

// Push with explicit length
lua_pushlstring(L, "hello", 5);

// Push formatted string
lua_pushfstring(L, "Value: %d", 42);
```

### 获取字符串

```c
// Get string (may be modified by GC after stack changes)
const char *s = lua_tostring(L, 1);

// Get string with length
size_t len;
const char *s = lua_tolstring(L, 1, &len);

// Check string (throws if not string)
const char *s = luaL_checkstring(L, 1);
```

> **警告**: `lua_tostring` 返回指向内部字符串的指针。在任何修改栈或触发 GC 的 C API 调用之后，该指针可能变得无效。如果后续需要使用该字符串，请立即复制它。

---

## 表操作

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

Userdata 允许 Lua 的垃圾回收器管理 C 数据。

### 轻量级 userdata（Light Userdata）

```c
// Pointer-sized, not GC-managed
void *ptr = malloc(100);
lua_pushlightuserdata(L, ptr);
// Caller is responsible for freeing ptr
```

### 完整 userdata（Full Userdata）

```c
// GC-managed block of memory
void *ud = lua_newuserdata(L, 100);  // Allocates 100 bytes
// ud is now on the stack as userdata
// Lua will free this memory when no longer referenced

// Attach metatable for behavior
luaL_getmetatable(L, "MyType");
lua_setmetatable(L, -2);
```

### 绑定 C 结构体

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

### 为 userdata 设置 metatable

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

## 错误处理

### 受保护的 C 调用

```c
// lua_pcall catches errors
if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    const char *err = lua_tostring(L, -1);
    fprintf(stderr, "Error: %s\n", err);
    lua_pop(L, 1);
}
```

### 从 C 中抛出错误

```c
// Push error message and longjmp
luaL_error(L, "invalid argument: %s", msg);

// Or push error manually
lua_pushnil(L);
lua_pushfstring(L, "error: %s", msg);
return 2;
```

### 跨 C 边界的错误处理

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

## 注册表（Registry）

**注册表**是一个用于存储 C 端数据的隐藏表：

```c
// Store value with unique key
lua_pushvalue(L, 1);                    // Value to store
int ref = luaL_ref(L, LUA_REGISTRYINDEX); // Get unique integer key
// ref is now a unique ID

// Retrieve value
lua_rawgeti(L, LUA_REGISTRYINDEX, ref);  // Push stored value

// Remove reference
lua_unref(L, LUA_REGISTRYINDEX, ref);
```

### 命名引用

```c
// Store with string key (easier to debug)
lua_pushvalue(L, 1);
lua_setfield(L, LUA_REGISTRYINDEX, "my_object");

// Retrieve
lua_getfield(L, LUA_REGISTRYINDEX, "my_object");
```

---

## 最小嵌入工作流

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

## 常见陷阱

### 1. 返回值数量不正确

```c
// BUG: Said 2 returns, only pushed 1
lua_pushnumber(L, 42);
return 2;  // Second value is garbage!

// FIX: Push all values before returning
lua_pushnumber(L, 42);
lua_pushstring(L, "ok");
return 2;
```

### 2. 使用过期指针

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

### 3. 栈不平衡

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

### 4. 未检查参数类型

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

### 5. 忘记设置 metatable

```c
// BUG: Userdata has no methods
Point *p = lua_newuserdata(L, sizeof(Point));
// No metatable set — can't call methods!

// FIX: Always set metatable for userdata
luaL_getmetatable(L, "Point");
lua_setmetatable(L, -2);
```

---

## 最佳实践

### 1. 使用 luaL_check* 进行验证

```c
// Always validate arguments
luaL_checknumber(L, 1);
luaL_checkstring(L, 2);
luaL_checktype(L, 3, LUA_TTABLE);
luaL_checkudata(L, 4, "Point");
```

### 2. 使用注册表存储稳定引用

```c
// Store callbacks/data in registry, not on stack
int ref = luaL_ref(L, LUA_REGISTRYINDEX);
// ref survives across C calls
```

### 3. 对不受信任的脚本使用保护调用

```c
// Use lua_pcall for any script execution
if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    const char *err = lua_tostring(L, -1);
    log_error(err);
    lua_pop(L, 1);
}
```

### 4. 记录栈状态

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

### 5. 在错误路径上清理资源

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

## 版本说明

### Lua 5.1

- `luaL_check*` 函数可用
- `lua_newuserdata` 可用
- `lua_pcall` 带错误处理函数（第 4 个参数）

### Lua 5.2/5.3

- `luaL_setfuncs` 替代了 `luaL_register`
- `luaL_newlib` / `luaL_newmetatable` 辅助函数
- `lua_rawlen` 用于获取原始长度（替代 `lua_objlen`）

### Lua 5.4

- `lua_newuserdatauv` 用于带用户值的 userdata
- `lua_resetthread` 用于协程重置
- `luaL_loadbufferx` 带模式参数
- 改进的错误消息

### LuaJIT

- FFI 库用于直接调用 C 函数，无需包装器
- `ffi.cdef` 用于 C 类型声明
- `ffi.cast` 用于类型转换
- C 互操作性能优秀

---

## 知识检查

<details>
<summary>1. 如果你压入了 3 个值但只返回 2 个会发生什么？</summary>

第三个值会留在栈上，导致栈泄漏。多次调用后，这可能会导致栈溢出。始终确保压入的值数量与返回数量匹配。
</details>

<details>
<summary>2. 为什么必须使用 <code>luaL_check*</code> 而不是 <code>lua_to*</code>？</summary>

`lua_to*` 在参数类型错误时返回默认值（0、NULL），会静默地导致 bug。`luaL_check*` 会抛出 Lua 错误，使类型不匹配立即可见。
</details>

<details>
<summary>3. 什么是注册表（Registry），为什么要使用它？</summary>

注册表是 `LUA_REGISTRYINDEX` 中的一个隐藏表，用于存储 C 端数据。它可以被状态中的任何 C 函数访问，提供了一个稳定的地方来存储回调、userdata 引用和其他持久化数据。
</details>

<details>
<summary>4. 为什么 <code>lua_pcall</code> 比 <code>lua_call</code> 更安全？</summary>

`lua_call` 在出错时执行 longjmp，这可能会跳过 C 清理代码并导致崩溃。`lua_pcall` 捕获错误并返回状态码，允许安全地进行清理。
</details>

<details>
<summary>5. 轻量级 userdata 和完整 userdata 有什么区别？</summary>

轻量级 userdata 只是一个指针 — Lua 不管理其内存。完整 userdata 是由 Lua 管理的内存块，具有 GC、metatable 支持和正确的生命周期管理。
</details>

---

## 关键要点

- **栈协议**: 所有数据交换都通过 push/pop/index 完成
- **C 函数**: 返回压入栈的值的数量
- **`luaL_check*`**: 始终验证参数（不要使用 `lua_to*`）
- **Userdata**: 使用 GC 和 metatable 将 C 数据绑定到 Lua
- **注册表（Registry）**: C 端引用的稳定存储
- **`lua_pcall`**: 跨 Lua/C 边界的错误安全处理
- **切勿使用 C 异常**跨越 Lua 边界
- **记录栈状态**在每个函数的入口/出口处

---

## 练习

### 初级（30–60 分钟）

1. **宿主时钟**: 将 `os.clock()` 暴露为 C 函数 `host_monotonic()`，返回高精度计时器。

2. **字符串拼接**: 编写一个 C 函数，连接 N 个字符串参数。

3. **表构建器**: 创建一个 C 函数 `make_table(k1, v1, k2, v2, ...)`，从交替的键值对构建 Lua 表。

### 中级（1–2 小时）

4. **Point 绑定**: 实现完整的 Point userdata，包含 `new(x,y)`、`add(other)`、`distance(other)` 和 `__tostring`。

5. **数组绑定**: 创建一个 C 支持的数组类型，包含 `get(i)`、`set(i, v)`、`length()` 以及 `__index`/`__newindex` 元方法。

6. **错误报告器**: 编写一个 C 函数，调用 Lua 回调并正确处理错误，包含栈跟踪。

### 高级（2–4 小时）

7. **模块加载器**: 实现一个 C 模块，通过 `require("mymod")` 注册自身并提供多个函数。

8. **嵌入框架**: 构建一个最小的嵌入框架，包含 `init()`、`load_script()`、`call_function()` 和 `shutdown()` 生命周期。

---

## 示例代码

本章的可运行示例：
- `examples/advanced/01-ecs-system.lua` — 使用类似 userdata 的模式
- `examples/projects/` — 嵌入项目的目标目录

---

## 扩展阅读

- [Lua 5.4 参考手册 — 第 4 节](https://www.lua.org/manual/5.4/manual.html#4)
- [Programming in Lua（第 4 版）— 第 28–29 章](https://www.lua.org/pil/)
- [下一章: 12 — 性能](12-performance.md)
