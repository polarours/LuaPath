# 可插拔脚本运行时

**级别**: 高级（阶段 4–5）
**时间**: 16–20 小时

## 概述

构建一个脚本运行时，它会：
- 从 `plugins/` 目录加载插件脚本
- 对每个插件做沙箱隔离（受限的 `_ENV`、受限的 `os`、禁用 `loadstring`）
- 支持热重载而无需重启宿主
- 提供类型明确的插件 API：`on_init()`、`on_tick(dt)`、`on_destroy()`
- 跟踪并隔离插件错误（一个插件失败不会拖垮其他插件）
- 向所有插件广播事件

## 架构

```
script-runtime/
├── src/
│   ├── runtime.lua       # Host loop: tick, dispatch, error isolation
│   ├── sandbox.lua       # Build restricted _ENV per plugin
│   ├── plugin-loader.lua # Scan dir, load modules, track state
│   └── event-bus.lua     # Publish/subscribe with wildcards
├── plugins/
│   └── _template.lua    # Plugin API template (copy for new plugins)
├── examples/
│   └── demo-plugins/
│       ├── counter.lua   # Simple state counter
│       └── event-echo.lua
└── tests/
    └── test_runtime.lua
```

## 插件 API 契约

```lua
-- plugins/my-plugin.lua
local M = {}

function M.on_init(config)
  -- called once at load; receive runtime-provided config table
end

function M.on_tick(dt)
  -- called every frame; dt = seconds since last tick
end

function M.on_destroy()
  -- cleanup; called before hot-reload or runtime shutdown
end

M.name    = "my-plugin"
M.version = "1.0.0"
return M
```

## 需求

- `Sandbox:build(plugin_table)` — 用受限表替换 `_ENV`；
  屏蔽：`os.execute`、`io`、`loadstring`、白名单之外的 `require`
- `Runtime:load_plugin(path)` — 在 pcall 中调用 `M.on_init(config)`；
  出错时记录日志并跳过
- `Runtime:hot_reload(plugin_id)` — 调用 `M.on_destroy()`，重新 require，再调用 `M.on_init()`
- `Runtime:tick(dt)` — 遍历所有存活的插件，在 pcall 中调用 `M.on_tick(dt)`
- `EventBus:emit(topic, payload)` — 分发给所有订阅者；
  支持 `topic.*` 通配符模式
- 所有 pcall 失败都只记录日志，绝不向外传播

## 运行方式

```bash
lua examples/demo-plugins/counter.lua   # run a single plugin in isolation
lua tests/test_runtime.lua
```
