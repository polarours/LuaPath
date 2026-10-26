# 交互式 Lua 演练场

可以直接在浏览器中运行 Lua 代码的在线环境。

## 快速开始

用这一行命令立刻试试 Lua：

```bash
lua -e 'print("Hello, Lua " .. _VERSION .. "!")'
```

或者把下面这段代码粘贴到任意在线演练场：

```lua
-- 快速 Lua 演示
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)
end

print("Factorial of 10:", factorial(10))
print("Lua version:", _VERSION)
print("Table example:", table.concat({1, 2, 3, 4, 5}, ", "))
```

## 推荐演练场

lua.org 和 luajit.org 都不再提供在线演练场了。它们当年链接的 `try.html`
现在都返回 404，而 lua.org 首页也完全没有演练场入口。下面每个 URL 都实测可达。

### 1. OneCompiler

**URL**：https://onecompiler.com/lua/

- 运行 Lua 5.4
- 在浏览器里运行，无需注册账号
- 支持从标准输入读入数据
- 适合快速测试语法

### 2. Tutorialspoint 在线编译器

**URL**：https://www.tutorialspoint.com/compilers/online-lua-compiler.htm

- 运行 Lua 5.3.5
- 带调试器的在线 IDE，无需安装
- 可分享代码链接
- 适合单步调试一段代码

### 3. Replit（完整 IDE）

**URL**：https://replit.com/languages/lua

- 带文件系统的完整 IDE
- 支持 Lua 5.3/5.4
- 可保存并分享项目
- 适合编写完整程序

### 4. Paiza.IO

**URL**：https://paiza.io/en/languages/lua

- 带运行按钮的在线编辑器
- 支持 stdin 输入
- 适合竞赛编程风格

### 5. Ideone

**URL**：https://ideone.com/lua

- 支持多个 Lua 版本
- 可分享代码链接
- 适合代码分享与讨论

**没有在线的 LuaJIT 演练场。** luajit.org 上没有任何演练场入口，它当年的
`try.html` 现在返回 404。改为本地安装——下面的「本地快速上手」一节有说明——
因为 FFI 和 JIT 特有行为在标准 Lua 上都试不出来。

## 演练场对比

`—` 表示该站点在首页没有说明这一项。

| 特性 | OneCompiler | Tutorialspoint | Replit | Paiza.IO | Ideone |
|---------|-------------|----------------|--------|----------|--------|
| Lua 版本 | 5.4 | 5.3.5 | 5.3/5.4 | 多个 | 多个 |
| 文件 I/O | — | — | ✓ | ✗ | ✗ |
| C API/FFI | — | — | ✗ | ✗ | ✗ |
| 保存项目 | — | — | ✓ | ✗ | ✗ |
| stdin 支持 | ✓ | — | ✓ | ✓ | ✓ |
| 分享链接 | ✓ | ✓ | ✓ | ✓ | ✓ |
| 完整 IDE | — | ✓ | ✓ | ✗ | ✗ |

## 交互式示例

### 示例 1：带函数的 Hello World

```lua
-- 函数声明
local function greet(name)
  return "Hello, " .. name .. "!"
end

-- 表格遍历
local names = {"Alice", "Bob", "Charlie"}
for _, name in ipairs(names) do
  print(greet(name))
end
```

### 示例 2：元表

```lua
-- 用元表实现简单的 OOP
local Person = {}
Person.__index = Person

function Person.new(name, age)
  return setmetatable({name = name, age = age}, Person)
end

function Person:introduce()
  return string.format("I'm %s, %d years old", self.name, self.age)
end

local p = Person.new("Lua", 30)
print(p:introduce())
```

### 示例 3：协程

```lua
-- 用协程实现生产者-消费者
local function producer()
  for i = 1, 5 do
    coroutine.yield(i)
  end
end

local co = coroutine.create(producer)
for i = 1, 5 do
  local ok, value = coroutine.resume(co)
  print("Received:", value)
end
```

### 示例 4：模式匹配

```lua
-- 字符串模式匹配
local text = "Email: user@example.com, Phone: 123-456-7890"

-- 提取邮箱
local email = text:match("[%w%.]+@[%w%.]+")
print("Email:", email)

-- 提取电话号码
local phone = text:match("%d%d%d%-%d%d%d%-%d%d%d%d")
print("Phone:", phone)
```

## 本地快速开始

如果你更习惯在本机运行：

```bash
# 安装 Lua 5.4（Ubuntu/Debian）
sudo apt-get install lua5.4

# 安装 Lua 5.3
sudo apt-get install lua5.3

# 安装 LuaJIT
sudo apt-get install luajit

# 快速 REPL
lua5.4        # 启动交互式 Lua 5.4
lua5.3        # 启动交互式 Lua 5.3
luajit        # 启动交互式 LuaJIT

# 运行一个文件
lua5.4 my_script.lua
```

## VS Code 配置

想要获得更好的本地体验：

1. 安装 [Visual Studio Code](https://code.visualstudio.com/)
2. 安装 sumneko 提供的 **Lua** 扩展
3. 新建一个 `.lua` 文件
4. 按 `Ctrl+F5` 运行

## Emacs 配置

```elisp
;; 添加到 init.el
(setq lua-default-directory "/path/to/LuaPath")
(setq lua-indent-level 2)
```

## Vim/Neovim 配置

```vim
" 添加到 init.vim 或 init.lua
let g:lua_syntax_conceal = 0
let g:loaded_lua = 1
```

## 故障排查

### 常见问题

1. **"attempt to call a nil value"**——你正在调用一个不存在的东西。检查拼写，并确认所需的库已加载。

2. **"index out of range"**——Lua 数组从 1 开始索引，而不是从 0 开始。用 `#table` 获取长度。

3. **"attempt to concatenate a nil value"**——你正在与 nil 拼接。检查变量在使用前是否已赋值。

4. **与版本相关的错误**——某些特性只存在于特定版本：
   - `//` 整除：Lua 5.3+
   - `goto`：Lua 5.2+
   - `<close>` 变量：Lua 5.4+

### 获取帮助

- 查看[术语表](../GLOSSARY.md)了解术语定义
- 阅读[常见陷阱](../pitfalls/)了解常见错误
- 参考[示例](../examples/)中的可用代码模式

## 使用演练场的技巧

1. **测试章节中的示例**——复制代码片段并运行
2. **尝试各种变体**——修改示例，观察行为变化
3. **检查版本差异**——在 Lua 5.3 和 5.4 上分别运行同一段代码
4. **用 print() 调试**——多数演练场只支持 stdout
5. **保存有价值的代码**——用 Replit 或本地文件持久化保存

## 在 LuaPath 中使用演练场

### 测试章节示例

1. 在 `examples/` 目录中找一个示例
2. 把代码复制到演练场
3. 运行并修改，以理解其行为
4. 换用不同的 Lua 版本，看看差异

### 测试路线图项目

1. 进入 `lua-mastery-roadmap/` 目录
2. 挑一个你感兴趣的项目
3. 把 `.lua` 文件内容复制到 Replit（多文件项目）
4. 单文件项目也可以直接粘贴到简易演练场

### 测试练习

1. 看看 `en/exercises/` 或 `zh/exercises/` 里的练习
2. 先在演练场里试着做出来
3. 卡住时查看 `en/exercises/beginner-solutions.md` 中的解答
4. 修改解答，探索其他解法

## 在线演练场的限制

- 不支持文件 I/O（多数沙箱）
- 不支持 C API / FFI
- 无法访问网络
- 运行时资源受限（内存、CPU）
- 没有持久化存储

如果练习需要文件 I/O、C API 或网络访问，请改用本地环境。
