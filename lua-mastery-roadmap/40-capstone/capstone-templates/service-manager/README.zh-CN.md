# 多服务进程管理器

**级别**: 生产级（阶段 5–40）
**时间**: 20–30 小时

## 概述

构建一个进程管理器，它会：
- 启动、停止和重启具名服务
- 每 N 秒做一次健康检查；失败时自动重启
- 以结构化 JSON 形式写入日志文件
- 提供可通过 Lua 查询的内存状态面板
- 重启退避：1s、2s、4s、8s（最大 30s）
- 收到 SIGTERM 等效信号时优雅关闭（通过停止信号触发）

## 架构

```
service-manager/
├── src/
│   ├── service.lua       # Service definition (name, command, health_check)
│   ├── manager.lua       # Process lifecycle: start, stop, restart, status
│   ├── health.lua        # Health check scheduler (coroutine-based)
│   ├── restart-policy.lua# Exponential backoff logic
│   ├── logger.lua        # Structured JSON logger
│   └── dashboard.lua     # Query: status, uptime, error counts
├── config/
│   └── services.lua      # Define services to manage
├── examples/
│   └── demo-services.lua
└── tests/
    ├── test_manager.lua
    └── test_restart-policy.lua
```

## 服务定义

```lua
-- config/services.lua
return {
  {
    name       = "web",
    command    = "lua examples/web-server.lua",
    health_url = "http://localhost:8080/health",
    restart    = { max_retries = 5, backoff = "exponential" },
    on_start   = function(id) print("web started") end,
  },
  {
    name       = "cache",
    command    = "lua examples/cache-server.lua",
    health_url = "http://localhost:8081/health",
    restart    = { max_retries = 3, backoff = "linear", interval = 2 },
  }
}
```

## 需求

- `Service:new(config)` — 校验配置，保存重启策略
- `Manager:start_all()` — 启动所有服务，返回状态表
- `Manager:health_check_all()` — 基于协程的周期性检查，
  失败时触发重启
- `RestartPolicy:next_delay(attempt)` — 指数退避：min(2^attempt, 30)
- `Logger:info/warn/error(module, msg, extra)` — 以 JSON 行写入文件
- `Dashboard:status(service_name)` — 返回 `{running, uptime, restarts, last_error}`

## 运行方式

```bash
lua examples/demo-services.lua
lua tests/test_manager.lua
```
