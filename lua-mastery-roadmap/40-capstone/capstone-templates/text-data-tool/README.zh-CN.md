# 文本数据工具

**级别**: 初级（阶段 1–3）
**时间**: 8–10 小时

## 概述

构建一个命令行文本数据处理工具，它会：
1. 读取一个文本文件
2. 按配置表中定义的转换链依次处理
3. 把结果写入输出文件或标准输出

## 架构

```
text-data-tool/
├── src/
│   ├── config.lua        # Load and validate config table
│   ├── transform.lua     # Chain of transform functions
│   └── main.lua          # CLI entry point
├── examples/
│   └── demo-config.lua  # Example config + input data
└── tests/
    └── test_main.lua    # Test suite
```

## 需求

- `config.lua` 导出 `load(path)`，返回校验通过的配置表
- `transform.lua` 导出 `apply(lines, transforms)`，其中 `transforms` 是由 `{name, params}` 组成的列表
- 支持的转换：`filter(pattern)`、`trim()`、`upper()`、`replace(old, new)`、`reverse()`
- `main.lua` 接受：`lua main.lua <input> <config.lua> [--output <file>]`
- 用 `pcall` 处理文件错误；打印结构化的错误消息
- 所有函数都返回值（除 I/O 外没有副作用）

## 运行方式

```bash
lua src/main.lua examples/sample.txt examples/demo-config.lua
```

## 测试套件

```bash
lua tests/test_main.lua
```
