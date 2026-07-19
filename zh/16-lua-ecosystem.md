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

## 延伸阅读

- [LuaRocks 文档](https://luarocks.org/)
- [Busted 文档](https://olivinelabs.com/busted/)
- [Lua 用户 Wiki](https://lua-users.org/)

---

[下一章：17 — 嵌入模式](17-embedding-patterns.md)
