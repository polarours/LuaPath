# LuaPath

面向实战的 Lua 学习路线图：工具、引擎、固件脚本和语言运行时。

[English](README.md) | [中文版](README_zh-CN.md)

## 理念

`LuaPath` 将 Lua 视为可编程的系统组件，而不仅仅是脚本语法。

设计原则：

- 概念优先，实现导向
- 最小化文字，最大化信息
- 可运行示例，显式陷阱
- 版本感知指导（Lua 5.1、5.3、5.4、LuaJIT）

## 快速统计

| 类别 | 数量 |
|------|------|
| 文档 | 20 章 × 2 种语言（EN + ZH） |
| 陷阱 | 15 篇 × 2 种语言（EN + ZH） |
| 示例 | 44 个可运行示例 |
| 术语表 | 107 术语（EN + ZH） |
| 路线图阶段 | 39 个（入门 → 高级） |

## 仓库结构

```
LuaPath/
├── en/                          20 章英文教程 (00–18)
├── zh/                          20 章中文教程（镜像 /en）
├── pitfalls/
│   ├── en/                      15 篇英文常见错误
│   └── 中文版/                   15 篇中文常见错误
├── lua-mastery-roadmap/
│   ├── 00-overview.md           分阶段学习路径
│   ├── 01-beginner/             阶段 1 项目
│   ├── 02-intermediate/         阶段 2 项目
│   ├── ...                      阶段 3-35 项目
│   └── 36-advanced/             阶段 36 项目
├── examples/
│   ├── beginner/                10 个入门示例
│   ├── intermediate/            14 个中级示例
│   ├── advanced/                15 个高级示例
│   └── projects/                5 个阶段项目（可运行）
├── exercises/                   分级练习（入门 → 高级）
├── references/                  速查表、版本差异
├── scripts/                     验证和测试工具
├── GLOSSARY.md                  107 术语参考
├── CONTRIBUTING.md              贡献指南
└── Makefile                     CI：validate、lint、check-links、parity、test
```

## 从这里开始

1. 阅读[路线图概览](lua-mastery-roadmap/00-overview.md)。
2. 从概念轨道中选择一章（`en/` 或 `zh/`）。
3. 阅读 `pitfalls/` 中一篇相关的常见错误文章。
4. 运行示例或构建项目来实践。

### 推荐入口

- **Table 与作用域：**
  [01 — 基础](zh/01-basics.md)、
  [04 — Table](zh/04-tables.md)、
  [意外全局变量](pitfalls/中文版/accidental-globals.md)、
  [table 长度未定义](pitfalls/中文版/table-length-undefined.md)

- **元表与 OOP：**
  [05 — 元表](zh/05-metatables.md)、
  [Metamethod 递归](pitfalls/中文版/metamethod-recursion.md)、
  [共享原型变异](pitfalls/中文版/shared-prototype-mutation.md)、
  [entity-model 项目](lua-mastery-roadmap/02-intermediate/entity-model/)

- **协程与并发：**
  [08 — 协程](zh/08-coroutines.md)、
  [协程 C 边界](pitfalls/中文版/coroutine-c-boundary.md)、
  [task-scheduler 项目](lua-mastery-roadmap/03-intermediate/task-scheduler/)

- **性能：**
  [12 — 性能](zh/12-performance.md)、
  [字符串拼接](pitfalls/中文版/string-concatenation-performance.md)、
  [GC 时机](pitfalls/中文版/gc-timing-assumptions.md)、
  [perf-analysis 项目](lua-mastery-roadmap/05-advanced/perf-analysis/)

## 支持的版本

- Lua 5.1
- Lua 5.3
- Lua 5.4
- LuaJIT

注意：

- 5.1 在环境模型（`setfenv`、`getfenv`）上不同，且缺少原生位运算符。
- 5.3 引入整数 + 位运算符。
- 5.4 引入 to-be-closed 变量和分代 GC 模式。
- LuaJIT：JIT 编译器 + trace 优化器，FFI 用于 C 互操作，基线接近 5.1 带扩展。

## 如何使用本仓库

1. 从 `00-roadmap.md` 或[路线图概览](lua-mastery-roadmap/00-overview.md)开始。
2. 按顺序学习各章。
3. 完成每个阶段的练习。
4. 在每个里程碑构建一个小项目。
5. 在生产嵌入前重温 `10`–`12`。
6. 编写或审查代码时，使用 `pitfalls/` 作为审查清单。

## 贡献

参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

欢迎贡献：

- 技术更正
- 版本特定的澄清
- 更好的诊断和边界情况示例
- 生产案例研究
- 新的陷阱文章（每篇一个常见错误）

---

如果你的目标只是语法，这个仓库会显得严格。
如果你的目标是构建可靠的 Lua 系统，这个仓库正是你需要的。
