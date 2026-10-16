# 第16章：Lua 生态系统

> **阶段**：高级  
> **前置章节**：第06章（模块）、第14章（生产环境）  
> **时间**：6–10小时  
> **Lua 版本**：5.1、5.3、5.4、LuaJIT

---

## 学习目标

学完本章后，你将能够：

1. 使用 LuaRocks 导航 Lua 包生态系统
2. 使用适当的工具设置开发环境
3. 使用 Lua 项目的测试框架
4. 了解 Lua 社区资源和约定
5. 为常见任务选择合适的库

---

## 使用 LuaRocks 进行包管理

### 安装

```bash
# 安装 LuaRocks
luarocks install --local mypackage

# 搜索包
luarocks search json

# 安装特定版本
luarocks install mypackage 1.0.0

# 列出已安装的包
luarocks list
```

### 创建自己的 Rocks

```lua
-- mypackage-scm-1.rockspec
package = "mypackage"
version = "scm-1"
source = {
  url = "git://github.com/user/mypackage.git",
  tag = "v1.0.0"
}
dependencies = {
  "lua >= 5.1",
  "luafilesystem >= 1.8"
}
build = {
  type = "builtin",
  modules = {
    mypackage = "src/mypackage.lua"
  }
}
```

### 流行的 Lua 库

| 类别 | 库 | 描述 |
|------|-----|------|
| HTTP | lua-http, luasocket | HTTP 客户端/服务器 |
| JSON | cjson, dkjson, lua-cjson | JSON 编解码 |
| 测试 | busted, luaunit | 测试框架 |
| 日志 | lua-log, logua | 日志库 |
| CLI | cliargs, penlight | 命令行解析 |
| 数据库 | luasql, pgmoon | 数据库驱动 |
| 序列化 | lua-cjson, serpent | 数据序列化 |

---

## 开发环境

### 推荐工具

1. **编辑器**：VS Code + Lua 扩展（sumneko）
2. **Linter**：luacheck 静态分析
3. **格式化器**：stylua 统一格式
4. **调试器**：本地 Lua 调试器或 IDE 集成
5. **性能分析器**：luaprofiler 或外部工具

### 项目结构

```
myproject/
├── src/
│   └── mymodule.lua
├── tests/
│   ├── test_mymodule.lua
│   └── helpers.lua
├── examples/
│   └── demo.lua
├── docs/
│   └── README.md
├── myproject-scm-1.rockspec
└── .luacheckrc
```

### 配置文件

```lua
-- .luacheckrc
std = "lua54"
globals = {
  "MY_GLOBAL"
}
read_globals = {
  "describe",
  "it",
  "assert"
}
```

---

## 使用 Busted 进行测试

### 安装

```bash
luarocks install busted
```

### 基本测试结构

```lua
-- tests/test_calculator.lua
local calculator = require("calculator")

describe("Calculator", function()
  describe("add", function()
    it("should add two numbers", function()
      assert.are.equal(5, calculator.add(2, 3))
    end)
    
    it("should handle negative numbers", function()
      assert.are.equal(-1, calculator.add(1, -2))
    end)
  end)
  
  describe("divide", function()
    it("should divide two numbers", function()
      assert.are.equal(2.5, calculator.divide(5, 2))
    end)
    
    it("should error on division by zero", function()
      assert.has_error(function()
        calculator.divide(1, 0)
      end)
    end)
  end)
end)
```

### 运行测试

```bash
# 运行所有测试
busted

# 运行特定文件
busted tests/test_calculator.lua

# 运行并显示覆盖率
busted --coverage

# 运行并显示输出
busted -o utfTerminal
```

---

## 代码质量工具

### Luacheck

```bash
# 安装
luarocks install luacheck

# 对项目运行
luacheck src/ tests/

# 自动修复
luacheck src/ --fix
```

### Stylua

```bash
# 安装
cargo install stylua

# 格式化代码
stylua src/

# 检查格式
stylua --check src/
```

---

## 社区资源

### 官方资源

- [Lua.org](https://www.lua.org/) — 官方网站
- [Lua 参考手册](https://www.lua.org/manual/5.4/) — 官方文档
- [Lua 编程书籍](https://www.lua.org/pil/) — 权威指南
- [Lua 用户 Wiki](https://lua-users.org/) — 社区 Wiki

### 社区

- [Lua Discourse](https://discuss.lua.org/) — 官方论坛
- [Reddit r/lua](https://reddit.com/r/lua) — 社区讨论
- [Stack Overflow](https://stackoverflow.com/questions/tagged/lua) — 问答

### 学习资源

- [Lua 快速入门](https://learnxinyminutes.com/docs/lua/) — 快速参考
- [Lua 教程](https://www.tutorialspoint.com/lua/) — 分步教程
- [Lua 程序设计](https://www.lua.org/pil/) — 综合书籍

---

## 版本兼容性

### 版本差异

| 特性 | 5.1 | 5.3 | 5.4 | LuaJIT |
|------|-----|-----|-----|--------|
| 整数 | 否 | 是 | 是 | 否 |
| 位运算 | 否 | 是 | 是 | 是 |
| 分代 GC | 否 | 否 | 是 | 否 |
| `goto` | 否 | 是 | 是 | 是 |
| `_ENV` | 否 | 是 | 是 | 部分 |

### 兼容性库

```lua
-- 为 5.2+ 提供 5.1 兼容性
local unpack = unpack or table.unpack

-- 5.1 的位运算
local bit = require("bit32") or require("bit")

-- 运行时检测版本
local function is_lua51()
  return _VERSION == "Lua 5.1"
end
```

---

## 案例研究：如何选依赖才不后悔

一个项目需要同时支持 Lua 5.1、5.3、5.4 和 LuaJIT，并且必须在可能没有安装
`luarocks` 的环境中运行。需求是 JSON 编码。前文已经列出了候选库（`cjson`、
`dkjson`、`json`）；本案例研究的是让"选哪个"这个决定可以撤销的那套机制。

### 要防住的失败模式

声明依赖只说明了你的期望。真正的失败是：在你改不了的环境里，到了**加载**时刻
才发现库不存在，然后整个进程跟着一起崩。因此这个决定要做两次：

1. **安装时** —— 在 `.rockspec` 里声明偏好顺序。
2. **加载时** —— 真正做一次探测，并且手里已经握着一个能用的降级实现。

### 探测

```lua
local function probe(name)
  local ok, mod = pcall(require, name)
  if ok then return { available = true, module = mod } end
  return { available = false, reason = tostring(mod) }
end

local JSON_CANDIDATES = { "cjson", "dkjson", "json" }
```

技巧就在于 `pcall(require, ...)`：模块不存在时它返回的是错误字符串而不是抛出
异常，于是"缺失"是一个被正常处理的条件，而不是一次崩溃。

在一台没有安装任何 JSON 库的机器上，探测会如实报告：

```
Dependency probe
----------------
  cjson                [missing]      not installed
  dkjson               [missing]      not installed
  json                 [missing]      not installed
  built-in fallback    [available]    stdlib only, always present

Selected encoder: built-in fallback
```

### 为什么降级实现必须是真的

这是最容易做错的地方。一个写成 `error("install cjson")` 的东西不是降级实现，
它是把原来的失败换了个说法再执行一遍。这里的降级实现是一个完整的、只用标准库的
编码器（约 60 行），处理了字符串转义、数组与对象的区分、循环 table 拒绝，以及
非有限数值：

```lua
-- JSON 没有 NaN/Infinity 的表示
if value ~= value or value == math.huge or value == -math.huge then
  error("cannot encode non-finite number: " .. tostring(value))
end
```

非有限数值满足 `value ~= value`，这就是在没有 `math.isnan` 时检测 NaN 的办法。
这两种情况，朴素的编码器都会悄无声息地产出非法 JSON。

### 如实报告差异

当确实存在偏好库时，该示例会把它输出与自带降级实现进行比对。逐字节相同是**被
报告、而不是被断言**的——键顺序和浮点格式在不同库之间本就存在合法差异：

```
Selected encoder (cjson) vs fallback byte-identical: false
  fallback output:
  {"empty_list":[],"enabled":true,"limits":{"cpu":0.5,...}}
```

在这里断言相等本身就是 bug：测试会因为外观原因失败，然后就会有人把它删掉。如实
报告既保留了信息，又不会制造一次假故障。

### 让降级实现保持存活

从不被执行的降级实现会悄悄腐坏——它从"存在快路径"的那天起就不再被跑到了。所以
内容校验会在**每一条可用路径**上都运行：

```
Content checks
--------------
  [cjson] ok   service name preserved
  [cjson] ok   array preserved
  [cjson] ok   newline escaped
  ...
  [fallback] ok   service name preserved
  [fallback] ok   array preserved
  ...
Cyclic input rejected: true
```

自己把两条路径都跑一遍：

```bash
# 降级路径（未安装 JSON 库）
lua examples/advanced/24-ecosystem-probe.lua

# 快路径（任何提供 .encode 函数的库）
LUA_PATH="/path/to/modules/?.lua;;" lua examples/advanced/24-ecosystem-probe.lua
```

已在 Lua 5.4、Lua 5.1 和 LuaJIT 2.1 上验证，全部退出码为 0。

### 依赖策略清单

在给 Lua 项目加第三方依赖之前，先回答这些问题：

- **有没有一个我愿意当作生产级看待的降级实现？** 没有的话，就写一个；否则就承认
  这个依赖是必需的，并在启动时响亮地失败。
- **版本约束够诚实地窄、够实际地宽吗？** `"cjson >= 2.1"` 和 `"cjson"` 的失败
  画像完全不同。
- **这个库支持我宣称支持的每一个 Lua 版本吗？** 本章前面那张版本对照表就是为
  这项检查而存在的。
- **依赖缺失时我能知道吗？** 带报告的探测会给你一行日志；不加保护的 `require`
  只会给你一个堆栈回溯。

---

## 最佳实践

1. **使用 LuaRocks** 进行包管理
2. **尽早设置 luacheck** 进行开发
3. **先写测试**再实现功能
4. **为团队协作记录 API**
5. **在生产环境中固定依赖版本**

---

## 核心要点

- LuaRocks 是 Lua 的标准包管理器
- Busted 提供现代测试框架
- Luacheck 和 stylua 确保代码质量
- 社区资源可用于学习和支持
- 版本兼容性需要仔细规划

---

## 练习

### 初级（30–60 分钟）

1. **包搜索**：使用 LuaRocks 搜索并安装一个 JSON 库。编写一个使用它解析 JSON 字符串的小脚本。

2. **代码检查**：对一个 Lua 文件运行 luacheck，修复它报告的所有警告。

### 中级（1–2 小时）

3. **编写 Busted 测试**：使用 Busted 的 describe/it/assert 语法为一个简单函数创建测试文件。使用 `busted` 运行它。

4. **创建 Rockspec**：为你编写的一个小 Lua 模块编写 `.rockspec` 文件。使用 `luarocks lint` 测试它。

### 高级（2–4 小时）

5. **CI/CD 流水线**：设置一个 GitHub Actions 工作流，在每次推送时运行 luacheck 和 busted 测试。

6. **版本兼容性包装器**：创建一个兼容层，在 Lua 5.1、5.3 和 5.4 之间提供一致的 API。

---

## 延伸阅读

- [LuaRocks 文档](https://luarocks.org/)
- [Busted 文档](https://olivinelabs.com/busted/)
- [Lua 用户 Wiki](https://lua-users.org/)

---

[下一章：17 — 嵌入模式](17-embedding-patterns.md)
