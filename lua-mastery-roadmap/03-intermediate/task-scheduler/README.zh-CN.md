# 协作式任务调度器

**阶段**: 3（中级）
**Lua 版本**: 5.1, 5.3, 5.4, LuaJIT

## 概述

一个完全基于协程构建的协作式任务调度器。本项目演示如何在没有操作系统线程的情况下组织并发任务——这一模式对事件驱动系统、游戏循环和网络服务器至关重要，在这些场景中确定性的调度比并行更重要。

## 学习内容

- 协程生命周期：创建、让出、恢复
- 协作式多任务（任务显式让出控制权）
- 优先级调度与超时处理
- 任务依赖解析

## 前置知识

- 第 08 章：协程（create、resume、yield）
- 第 09 章：标准库（table.sort、os.clock）

## 运行方法

```bash
lua 03-task-scheduler.lua
```

脚本会运行一组具有不同优先级和不同耗时的示例任务。

## 核心概念

- `coroutine.create` — 将函数包装为协程
- `coroutine.yield` — 暂停执行，将值返回给调用方
- `coroutine.resume` — 恢复一个已让出的协程
- `coroutine.status` — 检查协程是已结束、挂起还是运行中
- 轮询调度 vs 优先级调度

## 改进建议

1. 添加带硬/软时间限制的截止时间调度
2. 实现带共享取消的任务组
3. 在跨越让出边界时正确传播错误
4. 支持异步 I/O 集成（非阻塞的文件/网络操作）
5. 与 LuaJIT 协程做基准测试，以比较性能

## 文件

```
03-intermediate/task-scheduler/
├── README.md
├── README.zh-CN.md
├── 03-task-scheduler.lua      — 主实现
└── tests/
    └── task_scheduler_test.lua  — 示例任务与调度模式
```
