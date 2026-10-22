# CLI 框架

**阶段**: 9 — 高级 | **难度**: 高级

## 描述

一个命令行参数解析器，支持标志、位置参数、带值的选项、自动生成帮助信息以及版本输出。讲解用于构建开发者工具的字符串解析。

## 前置知识

- Lua 5.1+ 或 LuaJIT
- 熟悉命令行界面

## 运行方法

```bash
lua 01-cli-framework.lua --help
lua 01-cli-framework.lua --name Alice --verbose file.txt
```

## 核心概念

- 命令行参数解析
- 自动生成帮助文本
- 标志与选项的区别
- 子命令模式

## 文件

- `01-cli-framework.lua` — 支持标志、选项、帮助和版本输出的 CLI 解析器
