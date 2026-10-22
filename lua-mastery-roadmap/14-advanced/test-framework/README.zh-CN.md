# 测试框架

**阶段**: 14 — 高级

## 描述
创建一个精简但功能完整的测试框架，提供 describe/it/expect 风格的断言。了解测试运行器如何组织测试套件、setup/teardown 钩子如何管理状态，以及断言库如何给出有意义的失败信息。

## 前置知识
- 阶段 01–13 已完成
- 扎实理解闭包、表格和错误处理
- 熟悉 pcall/xpcall

## 运行方法
```bash
lua 01-test-framework.lua
```

## 核心概念
- 测试套件组织（describe/it）
- 带详细错误信息的断言模式
- setup/teardown 生命周期钩子
- 通过/失败计数与报告
- 嵌套 describe 块

## 文件
| 文件 | 描述 |
|------|-------------|
| `01-test-framework.lua` | 精简测试运行器，包含 describe/it/expect、断言和 setup/teardown |
