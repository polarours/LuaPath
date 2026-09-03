# 互操作模式

> **阶段**: 跨领域
> **前置知识**: 第 11 章 — Lua C API, 第 17 章 — 嵌入模式
> **预计时间**: 3–4 小时
> **适用版本**: 5.1, 5.3, 5.4, LuaJIT (C API 因版本而异)

---

## 什么是互操作?

互操作指 Lua 代码与用其他语言(最常见的是 C,因为 Lua C API 是扩展 Lua 的标准且性能最优的方式)编写的程序之间的通信。除 C 外,还存在 C++、Rust、Go、Python、Java 等语言的绑定,但它们都共享相同的基本模式:

1. **嵌入 (Embedding)**: 你的程序托管一个 Lua 解释器并运行 Lua 脚本
2. **扩展 (Extending)**: Lua 调用原生代码(C、Rust 等)
3. **双向**: 两者结合

---

## C API 作为基础

Lua C API 是一组 C 函数,让你可以:
- 创建和销毁 Lua 状态
- 读写 Lua 值
- 从 C 调用 Lua 函数
- 注册可从 Lua 调用的 C 函数

```c
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(int argc, char *argv[]) {
    lua_State *L = luaL_newstate();      // 创建状态
    luaL_openlibs(L);                   // 打开标准库

    // 运行 Lua 脚本
    if (luaL_dofile(L, "script.lua") != LUA_OK) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    lua_close(L);
    return 0;
}
```

---

## 向 Lua 注册 C 函数

### 基本模式

每个暴露给 Lua 的 C 函数都有相同的签名:

```c
// 必须是: int (*lua_CFunction)(lua_State *L)
static int l_my_function(lua_State *L) {
    // 读取参数: luaL_checknumber, luaL_checkstring 等
    double x = luaL_checknumber(L, 1);
    double y = luaL_checknumber(L, 2);

    // 执行操作
    double result = x + y;

    // 将结果压入栈
    lua_pushnumber(L, result);

    // 返回值数量 (Lua 可以有多个返回值)
    return 1;
}
```

注册方式:

```c
static const luaL_Reg mylib[] = {
    { "my_function", l_my_function },
    { NULL, NULL }  // 哨兵
};

// 在模块初始化时调用一次
luaL_newlib(L, mylib);  // Lua 5.2+
lua_setglobal(L, "mylib");
```

```lua
-- 现在可以从 Lua 调用
local r = mylib.my_function(3, 4)  -- r = 7
```

### 错误处理

C 函数可以引发 Lua 错误:

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

## 从 C 调用 Lua

### 调用 Lua 函数

```c
void call_lua_function(lua_State *L, double x) {
    // 将函数压入栈
    lua_getglobal(L, "my_lua_callback");

    // 压入参数
    lua_pushnumber(L, x);

    // 调用: 1 个参数, 1 个返回值, 0 表示无错误处理函数
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        fprintf(stderr, "Lua error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        return;
    }

    // 获取结果
    double result = lua_tonumber(L, -1);
    lua_pop(L, 1);  // 弹出结果

    printf("Result: %f\n", result);
}
```

```lua
-- Lua 端
function my_lua_callback(x)
    return x * x
end
```

### Lua Table 到 C Struct

在 Lua 和 C 之间传递结构化数据需要在表和结构体之间相互转换:

```c
// C: 将 table 作为键值选项对象读取
static int l_configure(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);

    // 读取字段
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

## Userdata 与元表

Userdata 让 C 可以将结构化数据附加到 Lua 值上,而 Lua 端无法伪造:

```c
// Counter userdata,拥有私有状态
typedef struct {
    int value;
} Counter;

static int l_counter_new(lua_State *L) {
    Counter *c = (Counter *)lua_newuserdata(L, sizeof(Counter));
    c->value = (int)luaL_optinteger(L, 1, 0);

    // 在 userdata 上设置元表
    luaL_getmetatable(L, "Counter");
    lua_setmetatable(L, -2);
    return 1;  // userdata 已在栈上
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
    { "inc",          l_counter_inc        },
    { "get",          l_counter_get        },
    { "__tostring",   l_counter_tostring   },
    { "__call",       l_counter_inc        },  // 允许 counter() 作为简写
    { NULL, NULL }
};

// 注册
static const luaL_Reg Counter_functions[] = {
    { "new", l_counter_new },
    { NULL, NULL }
};
```

```lua
local c = mylib.Counter.new(10)
print(c:get())    -- 10
c:inc(5)          -- 15
c(3)              -- 18  (通过 __call)
print(tostring(c)) -- Counter(18)
```

---

## Lua/C 数据转换

### 遍历 Lua Table

```c
// 从 C 遍历 Lua table
static int l_table_sum(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    double sum = 0;

    lua_pushnil(L);  // 第一个键
    while (lua_next(L, 1) != 0) {
        // 栈: ... key value
        if (lua_isnumber(L, -1)) {
            sum += lua_tonumber(L, -1);
        }
        lua_pop(L, 1);  // 弹出值,保留键供下次迭代
    }

    lua_pushnumber(L, sum);
    return 1;
}
```

```lua
local total = mylib.table_sum { 1, 2, 3, 4, 5 }  -- 15
```

### 字符串缓冲区

C 代码可以用 `luaL_Buffer` 高效构建字符串:

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
        luaL_addvalue(&b);  // 将栈顶值加入缓冲区
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

## 跨 C/Lua 边界的协程

挂起的 Lua 协程可以从 C 暂停并稍后恢复:

```c
// 从 C 恢复协程,向其传入一个值
static int l_resume_with(lua_State *L) {
    lua_State *co = *(lua_State **)luaL_checkudata(L, 1, "LuaThread");
    lua_xmove(L, co, 1);  // 将参数移动到协程的栈

    int status = lua_resume(co, L, 1);  // 1 个参数
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

## 异步与线程模式

### 原生线程调用 Lua

C 线程可以独立运行 Lua 代码:

```c
// 从 C 派生一个 Lua 线程
static int l_spawn_thread(lua_State *L) {
    lua_State *co = lua_newthread(L);  // 被压入父状态的栈

    // 加载 Lua 函数
    lua_getglobal(co, "worker");
    if (lua_type(co, -1) != LUA_TFUNCTION) {
        return luaL_error(L, "global 'worker' must be a function");
    }

    // 用初始值恢复
    lua_pushstring(co, "start");
    int status = lua_resume(co, L, 1);
    if (status == LUA_YIELD) {
        printf("Thread yielded: %s\n", lua_tostring(co, -1));
    }

    return 1;  // 返回该线程
}
```

---

## 跨边界内存管理

Lua 的垃圾回收器默认不会追踪 C 分配的内存。使用以下模式:

### 绑定生命周期

如果 C 分配了 Lua 必须最终释放的内存,使用终结器:

```c
// 创建带有 C 管理内存的 userdata 时:
static int l_alloc_buffer(lua_State *L) {
    size_t size = (size_t)luaL_checkinteger(L, 1);
    Buffer *buf = (Buffer *)lua_newuserdata(L, sizeof(Buffer));
    buf->data = malloc(size);
    buf->size = size;

    // 设置终结器: GC 收集此 userdata 时调用
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

### 弱表存储 C 对象引用

如果 Lua 需要持有 C 对象的引用而不阻止 GC:

```lua
-- Lua 端: 存储在弱表中
local refs = setmetatable({}, { __mode = "v" })

function register(obj)
    local handle = next_handle()
    refs[handle] = obj  -- 弱引用
    return handle
end
```

---

## 最佳实践

### 错误约定

选择一种策略并保持一致:

| 策略 | Lua 错误 | C 错误 |
|------|---------|--------|
| **向上传播** | `lua_error` / `luaL_error` | 从 C 函数返回错误字符串 |
| **返回 nil+error** | `return nil, "message"` | `lua_pushnil(L); lua_pushstring(L, err); return 2` |

```c
// 推荐: 返回 nil + 错误消息
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
-- 或者
local ok, err = mylib.may_fail()
if not ok then print(err) end
```

### API 版本检测

在编译时检测 Lua 版本:

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

### 命名约定

- C 函数: `l_<module>_<name>`
- Userdata 元表: `<Module>.<Name>`
- 常量: `LUA_<CONSTANT>` 风格

### 线程安全

**绝对不要**在未同步的情况下从多个 C 线程调用 Lua 函数。`lua_State` 不是线程安全的。如果需要并发 Lua 执行,请为每个 OS 线程创建一个 `lua_State`。

---

## 练习

1. **注册一个 C 模块**: 编写一个 C 模块,通过 Lua C API 暴露 `math_extra.gcd(a, b)` 和 `math_extra.lcm(a, b)`。从 Lua 测试它。

2. **带元表的 Userdata**: 实现一个 `Vector` userdata (x, y, z),从 C 提供 `__add`、`__mul` 和 `__len` 元方法。

3. **双向桥接**: 实现一个 C 函数,接收 Lua 回调并存入注册表,然后从另一个 C 函数回拨它。

4. **Table 到 struct 转换器**: 编写一个 C 函数,接收带有 `{host, port, timeout}` 字段的 Lua table 并打印它们,优雅地处理缺失字段。

---

## 关键要点

- **Lua C API 基于栈**: Lua 和 C 之间的所有通信都通过虚拟栈进行。
- **Userdata + 元表 = 不透明对象**: 这是向 Lua 公开 C struct 的安全方式。
- **向上传播错误**: 要么使用 `luaL_error()`,要么返回 `nil, err`——永远不要静默吞掉错误。
- **显式绑定生命周期**: 如果 C 分配由 Lua 管理的内存,使用 `__gc` 终结器。
- **每个线程一个状态**: `lua_State` 不是线程安全的;每个 OS 线程使用一个。
- **尽可能优先选择嵌入而非原始 C API**: 如果需要非 C 语言的 Lua-C 互操作,先寻找现有的绑定库。
