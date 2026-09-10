# 高级阶段

**阶段级别**: 16-20
**Lua 版本**: 5.1, 5.3, 5.4, LuaJIT

## 概述

本阶段专注于生产级模式，包括在 C 中嵌入 Lua、高级元编程和 Lua C API 集成。

## 项目

| 项目 | 描述 | 技能 |
|------|------|------|
| [嵌入 Lua](embed-lua/) | 在 C 应用中嵌入 Lua | C API、userdata |
| | | |

## 前置知识

- 理解 Lua 元表和 C API
- 熟悉 C 编程

## 运行方法

```bash
cd <project-name>/
# C 项目需要编译:
gcc -o embed_lua 05-embed-lua.c -l:liblua5.5.so -lm -ldl
./embed_lua
```
