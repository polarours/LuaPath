# 第 41 阶段：Mini HTTP Server（综合项目）

**级别**: 综合应用  
**描述**: 用 Lua 构建一个完整的、自包含的 HTTP 服务器框架，整合之前各阶段的所有概念——模块、元表、协程、错误处理、中间件管道和生产级模式。

## 前置知识

- 所有章节 (00–18)
- 第 6–40 阶段（模式项目）
- `en/05-metatables.md`
- `en/07-error-handling.md`
- `en/08-coroutines.md`
- `en/12-performance.md`
- `en/13-patterns.md`
- `en/14-lua-in-production.md`

## 学习目标

- 设计并实现模块化 HTTP 服务器框架
- 将原始 HTTP 请求解析为结构化数据
- 实现带路径参数的路由和方法分发
- 构建支持请求/响应拦截的中间件管道
- 使用协程进行并发连接处理
- 运用元编程实现简洁的 DSL 风格 API
- 将代码组织为可复用的 Lua 模块

## 架构

```
lua-http-server/
├── README.md              # 本文件
├── README.zh-CN.md        # 中文版说明文档
├── src/http/
│   ├── request.lua        # HTTP 请求解析器和表示层
│   ├── response.lua       # HTTP 响应构建器
│   ├── router.lua         # 基于方法和参数化的路由系统
│   ├── middleware.lua     # 链式中间件管道
│   ├── server.lua         # 带协程调度的 TCP 服务器
│   └── app.lua            # 统一的程序门面（DSL）
├── examples/
│   └── simple-server.lua  # 演示所有功能的完整示例
└── tests/
    └── http_server_tests.lua  # 各组件的测试套件
```

## 核心概念

| 概念 | 应用场景 |
|------|----------|
| 模块 | `src/http/*.lua` — 每个组件都是独立模块 |
| 元表 | `request.lua`, `response.lua` — 基于表的对象和方法 |
| 协程 | `server.lua` — 无外部库的异步连接处理 |
| 错误处理 | `router.lua`, `middleware.lua` — 结构化的错误响应 |
| 闭包 | 中间件管道 — 每个中间件闭包持有处理器状态 |
| 弱表 | 连接跟踪 — 允许 GC 回收已断开的客户端 |

## API 概览

框架使用流畅的 DSL 风格 API：

```lua
local app = require("app")

-- 中间件
app:use(function(req, res, next)
    print(req.method, req.path)
    next()
end)

-- 路由
app:get("/", function(req, res)
    return res:text("你好，LuaPath!")
end)

app:get("/users/:id", function(req, res)
    return res:json({ id = req.params.id })
end)

app:post("/echo", function(req, res)
    return res:json({ body = req.body })
end)

-- 启动服务器
app:run("127.0.0.1", 8080)
```

## 构建和测试

```bash
# 运行示例服务器（模拟模式，无需网络 I/O）
lua examples/simple-server.lua

# 运行测试套件
lua tests/http_server_tests.lua
```

## 预估时间

12–16 小时

## 交付物

1. **六个源模块**：覆盖请求解析、响应构建、路由、中间件、服务器和应用
2. **一个工作示例**：综合展示所有功能
3. **一个测试套件**：验证每个组件的正确性
