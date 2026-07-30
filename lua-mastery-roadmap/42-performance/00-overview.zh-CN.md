# Stage 42: Performance Patterns — Chinese Overview

**级别**: 高级  
**描述**: 通过理解内存布局、缓存行为和优化模式来编写高性能 Lua 代码。重点是减少缓存缺失、优化数据访问布局并利用 Lua 的快速路径。

## 前置知识

- Stage 12 — Performance
- Stage 27 — Memory Management
- 之前所有阶段

## 学习目标

- 设计缓存局部性优化的数据结构
- 理解 Lua 内部内存布局和分配模式
- 在热路径上应用结构优化
- 测量和验证性能改进

## 项目

1. [缓存友好模式](42-performance/cache-friendly/) — AoS vs SoA 优化
2. [SIMD 模式](42-performance/simd-patterns/) — Lua 表格的向量化操作  
3. [内存对齐](42-performance/memory-alignment/) — 高效布局和填充模式

## 预估时间

每个项目 8–12 小时
