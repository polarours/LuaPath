# 性能分析

**阶段**: 5（高级）
**Lua 版本**: 5.1, 5.3, 5.4, LuaJIT

## 概述

一个性能分析工具包，用于演示性能剖析技术、内存分配优化和 GC 调优。本项目讲授如何定位热路径、测量执行时间，以及针对生产负载优化 Lua 代码。

## 学习内容

- 使用 `os.clock` 和 `collectgarbage` 进行性能剖析
- 字符串拼接的替代方案（`table.concat` vs `..`）
- 局部变量与全局变量的性能影响
- 表复用与预分配策略

## 前置知识

- 第 12 章：性能（基准测试、优化）
- 第 13 章：设计模式（高效的模式使用）
- 第 14 章：Lua 在生产环境中的应用（部署方面的考量）

## 运行方法

```bash
lua 04-perf-analysis.lua
```

脚本会运行多个基准测试，对比不同的 Lua 编码模式。

## 核心概念

- `os.clock` — 高分辨率的 CPU 时间测量
- `collectgarbage("count")` — 内存占用跟踪
- `collectgarbage("collect")` — 强制垃圾回收
- `table.concat` — O(n) 的字符串构建 vs O(n²) 的字符串拼接
- 局部变量作用域 — 避免全局表查找

## 改进建议

1. 添加针对 LuaJIT 的基准测试，并检测 JIT 预热
2. 使用 `debug.sethook` 实现函数级性能剖析
3. 添加按函数划分的内存分配跟踪
4. 创建带统计分析的可复用基准测试框架
5. 比较 Lua 5.4 的分代 GC 与增量 GC 模式

## 文件

```
05-advanced/perf-analysis/
├── README.md
├── README.zh-CN.md
├── 04-perf-analysis.lua      — 主要基准测试
└── tests/
    └── perf_analysis_test.lua  — 单个基准测试用例
```
