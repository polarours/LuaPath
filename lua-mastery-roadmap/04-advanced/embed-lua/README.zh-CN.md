# 在 C 中嵌入 Lua

**阶段**: 4（高级）
**Lua 版本**: 5.1, 5.3, 5.4

## 概述

一个在 C 宿主应用中嵌入 Lua 虚拟机的完整示例。本项目讲授 C API、用户数据的创建、元表绑定以及规范的栈纪律——这些是构建宿主应用、向 Lua 脚本暴露原生功能所必需的技能。

## 学习内容

- `lua_State` 的生命周期管理
- 在 Lua 栈上压入和弹出值
- 创建包含内嵌 C 数据的用户数据
- 将 C 函数和元表绑定到用户数据
- 跨越 Lua-C 边界的错误处理

## 前置知识

- 第 10 章：Lua 内部机制（VM 模型、内存分配）
- 第 11 章：Lua C API（栈操作、类型检查）

## 构建方法

```bash
gcc -o embed_lua 05-embed-lua.c -llua -lm
```

在 macOS 上使用 Homebrew：
```bash
gcc -o embed_lua 05-embed-lua.c -I/usr/local/include/lua5.4 -L/usr/local/lib -llua -lm
```

## 运行方法

```bash
./embed_lua
```

宿主应用会向 Lua 脚本暴露一个日志器和一个指标表。

## 核心概念

- `lua_State` — 隔离的 Lua 执行环境
- `lua_push*` 系列 — 将值压入栈
- `luaL_check*` 系列 — 带类型检查的取值
- `lua_newuserdata` — 为 Lua 分配宿主管理的内存
- `luaL_setmetatable` — 为用户数据关联元表
- 栈纪律 — 在 API 边界两侧保持 push/pop 平衡

## 改进建议

1. 使用 `lua_newthread` 和 `lua_resume` 添加线程安全的访问
2. 用自定义分配器实现内存上限
3. 通过 `luaL_Reg` 数组添加函数注册
4. 创建带初始化/清理流程的可复用宿主库
5. 使用 `lua_pcall` 和 `lua_atpanic` 添加错误恢复

## 文件

```
embed-lua/
├── README.md        ← 本文件
├── 05-embed-lua.c   ← C 宿主应用
├── script.lua       ← 由宿主加载的 Lua 脚本
└── Makefile         ← 构建说明
```
