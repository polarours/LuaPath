# 并发模式
**阶段:** 25 — 高级

## 描述
实现基于协程的并发模式，包括参与者模型、CSP 通道以及 async/await 模拟。探索 Lua 的轻量协程如何实现协作式多任务，而无需操作系统线程。

## 前置知识
- 阶段 1–24 已完成
- 扎实的 Lua 协程与闭包基础
- 熟悉元表与元方法

## 运行方法
```bash
lua 01-concurrency-patterns.lua
```

## 核心概念
- 使用消息传递的参与者模型
- CSP（通信顺序进程）通道
- 使用协程包装器实现的 async/await 模式
- 协作式调度与 yield/resume
- 通道缓冲与选择

## 文件
- `01-concurrency-patterns.lua` — 基于协程的参与者模型、CSP 通道与 async/await
