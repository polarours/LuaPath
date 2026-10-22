# 响应式数据管道

**级别**: 中级（阶段 2–4）
**时间**: 12–16 小时

## 概述

构建一条响应式数据管道，它会：
- 串联操作符（map、filter、reduce、window）
- 通过协程支持异步数据源
- 实现背压（有界缓冲区）
- 在管道中传播错误
- 保持清晰的模块结构

## 架构

```
reactive-pipeline/
├── src/
│   ├── pipeline.lua    # Core: operator chain + scheduling
│   ├── operators.lua   # Built-in operators
│   ├── source.lua      # Async source (coroutine-based)
│   └── sink.lua        # Output sink (file, callback, bounded queue)
├── examples/
│   └── weather-stream.lua  # Simulated weather data stream
└── tests/
    └── test_pipeline.lua
```

## 需求

- `Pipeline` 对象，带 `:pipe(op1, op2, ..., sink)` 方法
- 操作符：`map(fn)`、`filter(fn)`、`reduce(fn, init)`、`window(n)`
- `Source:create(coro_fn)` — 包装一个 yield 值的协程
- `Sink:bounded(max_size)` — 满了就丢弃最旧的项
- 操作符中的错误传播到 `pipeline:error_handler`
- 每个模块都是一个普通表，带 `:new()` 或模块级函数
- 不使用全局变量；采用 `local M = {} ... return M` 模式

## 运行方式

```bash
lua examples/weather-stream.lua
lua tests/test_pipeline.lua
```
