# 术语表（GLOSSARY）

LuaPath 中使用的技术术语与概念。

## A

### Array Part (数组部分)
Lua 表中以连续整数键（1、2、3……）存储值的那一部分。Lua 对这一段采用数组索引而非哈希查找来优化访问。参见：[04-tables.md](zh/04-tables.md)

### Upvalue (上值)
来自外层函数作用域、被嵌套函数（闭包）捕获的变量。上值让闭包能够在多次调用之间保持状态。参见：[03-functions.md](zh/03-functions.md)、[10-lua-internals.md](zh/10-lua-internals.md)

## B

### Bytecode (字节码)
Lua 编译器生成的中间表示。虚拟机执行的是字节码指令，而不是直接执行源代码。参见：[10-lua-internals.md](zh/10-lua-internals.md)

## C

### Closure (闭包)
函数与其上值（被捕获的外部变量）的组合。闭包支撑函数式编程模式和带状态的函数。参见：[03-functions.md](zh/03-functions.md)

### Coroutine (协程)
一种可以协作式让出控制权的轻量执行线程。协程无需付出操作系统线程的开销即可实现异步模式。参见：[08-coroutines.md](zh/08-coroutines.md)

## D

### Dispatch (分派)
确定应当调用哪个函数或方法的过程。在 Lua 中，元表通过元方法定制分派行为。参见：[05-metatables.md](zh/05-metatables.md)

## E

### ECS (实体组件系统)
一种架构模式：实体是 ID，组件是数据，系统是逻辑。在游戏开发中很流行，因为它的数据布局对缓存友好。参见：[13-patterns.md](zh/13-patterns.md)

### Environment (环境)
为某个代码块（chunk）保存全局变量的表。在 Lua 5.2+ 中，`_ENV` 取代了 `setfenv`/`getfenv`。参见：[01-basics.md](zh/01-basics.md)、[06-modules.md](zh/06-modules.md)

## F

### FFI (外部函数接口)
LuaJIT 的特性，允许直接调用 C 函数，而无需编写 C API 包装代码。参见：[11-lua-c-api.md](zh/11-lua-c-api.md)

### Full Userdata (完整用户数据)
拥有一块内存的 Lua 对象。这块内存由 Lua 分配，并随该用户数据一起被垃圾回收。与轻量用户数据相对。参见：[11-lua-c-api.md](zh/11-lua-c-api.md)

## G

### Garbage Collection (垃圾回收)
自动回收已不再被使用的对象所占内存的内存管理机制。Lua 使用增量式标记-清除算法（在 5.4 中还提供分代模式）。参见：[10-lua-internals.md](zh/10-lua-internals.md)、[12-performance.md](zh/12-performance.md)

#### Incremental GC (增量 GC)
把标记与清除拆成若干小步骤交替执行、以避免长时间停顿的 GC。是 Lua 5.1-5.4 的默认策略。

#### Generational GC (分代 GC)
比老对象更频繁地回收年轻对象的 GC。可用于 Lua 5.4+。更适合短生命周期分配较多的负载。

## H

### Hash Part (哈希部分)
Lua 表中以非连续或非整数键存储值的那一部分。采用哈希表查找。参见：[04-tables.md](zh/04-tables.md)

## J

### JIT Compiler (JIT 编译器)
在运行时把字节码翻译成本地机器码的即时编译器。LuaJIT 内置了带追踪优化的 JIT 编译器。参见：[12-performance.md](zh/12-performance.md)

## L

### Light Userdata (轻量用户数据)
存储在 Lua 中的简单 C 指针值。它不拥有内存，也没有元表。与完整用户数据相对。参见：[11-lua-c-api.md](zh/11-lua-c-api.md)

### Local Variable (局部变量)
用 `local` 声明的变量。局部变量比全局变量更快，因为它们映射到虚拟机寄存器或上值，而不是表查找。参见：[01-basics.md](zh/01-basics.md)

### LuaJIT
带扩展的 Lua 5.1 即时编译实现。性能提升显著，但与 PUC Lua 在部分行为上存在差异。参见：[README.md](README_zh-CN.md)

## M

### Metatable (元表)
当另一个表被特定操作（索引、算术等）访问时，用于定义其自定义行为的表。参见：[05-metatables.md](zh/05-metatables.md)

### Metamethod (元方法)
元表中处理某个特定操作的函数。例如：`__index`、`__newindex`、`__add`、`__call`。参见：[05-metatables.md](zh/05-metatables.md)

### Module (模块)
导出功能的可复用代码单元。Lua 模块通常是由 `require` 加载的文件所返回的表。参见：[06-modules.md](zh/06-modules.md)

## O

### Open Upvalue (打开的上值)
仍然引用栈上变量（所属函数尚未返回）的上值。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Closed Upvalue (关闭的上值)
因为所属函数已经返回，其值已从栈移到堆上结构中的上值。参见：[10-lua-internals.md](zh/10-lua-internals.md)

## P

### Prototype Pattern (原型模式)
一种 OOP 替代方案：新对象通过复制已有对象（原型）来创建，而不是实例化类。在 Lua 中很常见。参见：[05-metatables.md](zh/05-metatables.md)、[13-patterns.md](zh/13-patterns.md)

### PUC Lua
来自里约热内卢天主教大学的 Lua 参考实现。与 LuaJIT 相区别。

## R

### Register-Based VM (基于寄存器的虚拟机)
Lua 的 VM 架构：指令直接引用虚拟寄存器（与基于栈的 VM 相对）。参见：[10-lua-internals.md](zh/10-lua-internals.md)

## S

### Sandboxing (沙箱)
限制 Lua 脚本对危险函数和资源的访问。运行不受信任的代码时必不可少。参见：[14-lua-in-production.md](zh/14-lua-in-production.md)

### Sequence (序列)
键为从 1 到 n 的连续整数的表。长度运算符 `#` 只对序列有明确定义。参见：[04-tables.md](zh/04-tables.md)

### SoA (结构体数组)
一种数据布局模式：每个字段分别存放在独立的数组中，可提升遍历时的缓存效率。与 AoS（Array of Structures，数组结构体）相对。参见：[13-patterns.md](zh/13-patterns.md)

## T

### Table (表)
Lua 的主要数据结构。通过数组与哈希混合的设计实现了数组、映射、对象等多种用途。参见：[04-tables.md](zh/04-tables.md)

### Trace (追踪，LuaJIT)
被 LuaJIT 的 JIT 编译器优化成本地机器码的一段热路径代码（追踪）。参见：[12-performance.md](zh/12-performance.md)

### Truthiness (真值)
Lua 的布尔求值规则：只有 `false` 和 `nil` 是假值，其他一切（包括 `0` 和 `""`）都是真值。参见：[01-basics.md](zh/01-basics.md)

## U

### Upvalue (上值)
参见：闭包

### Userdata (用户数据)
用于表示不透明 C 数据的 Lua 类型。分为两种形式：轻量用户数据（指针）和完整用户数据（拥有内存）。参见：[11-lua-c-api.md](zh/11-lua-c-api.md)

## V

### VM (虚拟机)
执行 Lua 字节码的运行时引擎。参见：[10-lua-internals.md](zh/10-lua-internals.md)

---

## 版本相关术语

### setfenv / getfenv (Lua 5.1)
获取/设置函数环境的函数。在 Lua 5.2+ 中被 `_ENV` 取代。

### _ENV (Lua 5.2+)
保存当前环境的普通变量。取代了 `setfenv`/`getfenv`。

### Integer Subtype (整数子类型，Lua 5.3+)
Lua 5.3+ 区分整数与浮点数，并新增了位运算符和整数除法（`//`）。

### To-Be-Closed Variables (待关闭变量，Lua 5.4+)
用 `<close>` 标记的变量，在离开作用域时会被自动关闭。

---

## F（补充）

### Finalizer (终结器)
对象被垃圾回收时调用的函数。通过 `__gc` 元方法实现。可以用于清理，但绝不要依赖它确定的执行时机。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Flyweight Pattern (享元模式)
在许多对象之间共享公共数据以减少内存占用的模式。参见：[13-patterns.md](zh/13-patterns.md)

### Finite State Machine (有限状态机)
一种包含状态与状态转移的计算模型。Lua 使用表和元表来实现有限状态机（FSM）。参见：[12-advanced/state-machine/](lua-mastery-roadmap/12-advanced/state-machine/)、[23-advanced/fsm-advanced/](lua-mastery-roadmap/23-advanced/fsm-advanced/)

## I（补充）

### Inspector Function (检查函数)
在不修改数据结构的前提下检查并报告其状态的函数。对调试非常有用。参见：[debugging-guide.md](zh/debugging-guide.md)

## P（补充）

### Proxy Table (代理表)
通过元表拦截操作，以控制访问、校验输入或记录行为的表。常见于只读模式和校验场景。参见：[05-metatables.md](zh/05-metatables.md)

## R（补充）

### RAII (资源获取即初始化)
一种把资源生命周期与对象作用域绑定在一起的模式。Lua 5.4 的 `<close>` 变量实现了这一模式。参见：[14-lua-in-production.md](zh/14-lua-in-production.md)

### Reflection (反射)
在运行时检查并修改代码结构。`debug` 库提供了 Lua 的反射能力。参见：[debugging-guide.md](zh/debugging-guide.md)

## 补充术语

### Accumulator (累加器)
在迭代过程中收集结果的变量。常见于 reduce/fold 操作。参见：[03-functions.md](zh/03-functions.md)

### Adapter Pattern (适配器模式)
把一种接口转换为另一种接口的模式，使互不兼容的接口能够协同工作。参见：[13-patterns.md](zh/13-patterns.md)

### Actor Model (参与者模型)
一种通过消息传递进行通信的并发模型。每个参与者拥有自己的状态和邮箱。参见：[25-advanced/concurrency-patterns/](lua-mastery-roadmap/25-advanced/concurrency-patterns/)

### Closure (闭包)
捕获外层作用域中变量的函数。闭包在 Lua 中是一等公民，可支撑强大的函数式编程模式。参见：[03-functions.md](zh/03-functions.md)

### Continuation (延续)
计算剩余部分的一种表示。Lua 中的协程提供非对称延续。参见：[08-coroutines.md](zh/08-coroutines.md)

### Coroutine (协程)
可挂起并恢复的轻量执行线程。Lua 协程是协作式的，且是非对称的。参见：[08-coroutines.md](zh/08-coroutines.md)

### Dead Code (死代码)
永远不会被执行到的代码。通常是重构不完整或分支不可达的结果。参见：[debugging-guide.md](zh/debugging-guide.md)

### Dependency Injection (依赖注入)
依赖由外部提供、而不是在内部创建的模式。可降低耦合并提升可测试性。参见：[06-modules.md](zh/06-modules.md)

### DSL (领域特定语言)
为某个特定问题域设计的小语言。Lua 的灵活性使它非常适合构建内部 DSL。参见：[15-advanced-metaprogramming.md](zh/15-advanced-metaprogramming.md)

### Event-Driven Programming (事件驱动编程)
程序流程由用户操作、消息或传感器输出等事件决定的编程范式。参见：[11-event-system.lua](examples/advanced/11-event-system.lua)

### Garbage Collection (垃圾回收)
自动回收已不再被使用的对象所占内存的内存管理机制。Lua 使用增量式标记-清除 GC。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Generational GC (分代 GC)
一种比老对象更频繁地回收年轻对象的 GC 策略。可用于 Lua 5.4+。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Global Environment (全局环境)
存放全局变量的默认表。在 Lua 5.1 中通过 `_G` 访问；在 5.2+ 中，`_ENV` 就是环境。参见：[01-basics.md](zh/01-basics.md)

### Hash Table (哈希表)
使用哈希函数把键映射到值的数据结构。Lua 表对非连续键使用哈希表。参见：[04-tables.md](zh/04-tables.md)

### Hook (钩子)
Lua 调试库在特定事件（调用、返回、逐行）时调用的函数。用于调试和性能分析。参见：[debugging-guide.md](zh/debugging-guide.md)

### Hot Path (热路径)
执行频繁、对性能影响最大的代码段。参见：[12-performance.md](zh/12-performance.md)

### Immutable (不可变)
创建之后无法再改变的值。Lua 字符串是不可变的，table 则是可变的。参见：[04-tables.md](zh/04-tables.md)

### Iterator (迭代器)
从集合中依次返回元素的函数。Lua 内置了 `pairs` 和 `ipairs` 两个迭代器。参见：[02-control-flow.md](zh/02-control-flow.md)

### Lazy Evaluation (惰性求值)
把计算推迟到真正需要结果时才进行。Lua 是急切求值的，但基于协程的生成器可以模拟惰性求值。参见：[08-coroutines.md](zh/08-coroutines.md)

### Local Variable (局部变量)
用 `local` 声明的变量。局部变量比全局变量快，因为它们映射到虚拟机寄存器。参见：[01-basics.md](zh/01-basics.md)

### Macro (宏)
一种代码转换形式。Lua 没有 C 风格的宏，但使用 `string.gsub` 和 `load` 可以达到类似效果。参见：[15-advanced-metaprogramming.md](zh/15-advanced-metaprogramming.md)

### Memoization (记忆化)
缓存函数结果以避免重复计算的一种优化技术。参见：[03-functions.md](zh/03-functions.md)

### Metamethod (元方法)
元表中为某个特定操作（索引、算术等）定义行为的函数。例如：`__index`、`__newindex`、`__add`。参见：[05-metatables.md](zh/05-metatables.md)

### Nil (空值)
Lua 表示值缺失的方式。`nil` 和 `false` 都是假值。参见：[01-basics.md](zh/01-basics.md)

### Object (对象)
在 Lua 中，任何 table 都可以充当对象。对象通过元表和方法获得行为。参见：[05-metatables.md](zh/05-metatables.md)

### Operator Overloading (运算符重载)
通过元方法为标准运算符（+、-、* 等）定义自定义行为。参见：[05-metatables.md](zh/05-metatables.md)

### Pattern (模式)
用于匹配文本的模板。Lua 模式使用 `%d`、`%w`、`.`、`*`、`+`、`-`（并非正则表达式）。参见：[09-standard-library.md](zh/09-standard-library.md)

### Pool (池)
一组可复用的对象，避免反复分配/释放。参见：[21-advanced/object-pool/](lua-mastery-roadmap/21-advanced/object-pool/)

### Preprocessor (预处理器)
在执行之前对源码进行转换的代码。Lua 的 `string.gsub` 和 `load` 可以充当轻量级预处理器。参见：[15-advanced-metaprogramming.md](zh/15-advanced-metaprogramming.md)

### Priority Queue (优先队列)
按优先级而非插入顺序出队的数据结构。参见：[22-advanced/pub-sub-system/](lua-mastery-roadmap/22-advanced/pub-sub-system/)

### Promise
未来某个值的占位符。Lua 没有原生的 Promise；协程和回调承担着类似角色。参见：[08-coroutines.md](zh/08-coroutines.md)

### Proxy (代理)
控制对另一个对象访问的中间层。用于日志记录、校验和只读保护。参见：[05-metatables.md](zh/05-metatables.md)

### Queue (队列)
一种 FIFO（先进先出）数据结构。使用带头尾索引的表实现。参见：[33-advanced/lock-free-queue/](lua-mastery-roadmap/33-advanced/lock-free-queue/)

### Async/Await (异步/等待)
一种写出看起来像同步代码的异步代码的模式。在 Lua 中，通过带 yield/resume 的协程实现。参见：[25-advanced/concurrency-patterns/](lua-mastery-roadmap/25-advanced/concurrency-patterns/)

### Assertion (断言)
当条件为假时抛出错误的运行时检查。用于前置条件校验和调试。参见：[07-error-handling.md](zh/07-error-handling.md)

### Backpressure (背压)
较慢的消费者向较快的生产者发出信号、让其减速的机制。在协程中通过通道或有界队列实现。参见：[08-coroutines.md](zh/08-coroutines.md)

### Bitwise Operations (位运算)
对整数的单个位进行操作。Lua 5.3+ 原生支持；在 5.1 中可通过 `bit32` 库使用。参见：[01-basics.md](zh/01-basics.md)

### Builder Pattern (建造者模式)
逐步构建复杂对象、把构造与表示分离的模式。参见：[13-patterns.md](zh/13-patterns.md)

### Callback (回调)
作为参数传给另一个函数、供稍后调用的函数。是事件驱动与异步编程的基础。参见：[03-functions.md](zh/03-functions.md)

### Chain of Responsibility (责任链模式)
一种请求在一串处理者之间传递、由每个处理者决定是处理还是继续向下传递的模式。参见：[13-patterns.md](zh/13-patterns.md)

### Chunk (代码块)
被编译器翻译成字节码的一段 Lua 代码。可以是文件、字符串或函数。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Collector (回收器)
负责回收无用内存的垃圾回收组件。Lua 使用增量式标记-清除。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Command Pattern (命令模式)
把请求封装成对象的模式，从而支持撤销/重做、排队和日志记录。参见：[13-patterns.md](zh/13-patterns.md)

### Continuation (延续)
计算剩余部分的一种表示。协程提供非对称延续。参见：[08-coroutines.md](zh/08-coroutines.md)

### CSP (通信顺序进程)
一种进程通过通道进行通信的并发模型。Lua 使用协程和带缓冲的通道来实现它。参见：[25-advanced/concurrency-patterns/](lua-mastery-roadmap/25-advanced/concurrency-patterns/)

### Code Generation (代码生成)
在运行时通过字符串操作和 load() 创建代码。用于 DSL 和元编程。参见：[26-advanced/code-generation/](lua-mastery-roadmap/26-advanced/code-generation/)

### Deadlock (死锁)
两个或多个协程相互等待、导致无法继续推进的局面。Lua 协程是协作式的，因此死锁需要显式 yield 才会发生。参见：[08-coroutines.md](zh/08-coroutines.md)

### Data Pipeline (数据流水线)
一系列可以组合在一起的数据处理步骤（map、filter、reduce）。参见：[24-advanced/data-pipeline/](lua-mastery-roadmap/24-advanced/data-pipeline/)

### Decorator Pattern (装饰器模式)
包装对象以动态添加行为、而不修改原对象的模式。参见：[13-patterns.md](zh/13-patterns.md)

### Deep Copy (深拷贝)
创建一个新表，它是原表（含嵌套表）的完整独立副本。与浅拷贝相对。参见：[04-tables.md](zh/04-tables.md)

### DSL (领域特定语言)
为某个特定问题域设计的小语言。Lua 的语法使它非常适合构建 DSL。参见：[13-patterns.md](zh/13-patterns.md)

### Dustman
LuaJIT 中用于清理弱引用的概念。在 PUC Lua 中并非标准特性。参见：[12-performance.md](zh/12-performance.md)

### Entity Component System (实体组件系统，ECS)
一种架构模式：实体是 ID，组件是数据，系统是逻辑。在游戏开发中很流行。参见：[13-patterns.md](zh/13-patterns.md)

### Exposure (暴露)
让模块内部的函数或数据对外可见。通过返回表和局部作用域来控制。参见：[06-modules.md](zh/06-modules.md)

### Expression (表达式)
由值、变量、运算符和函数组合而成、求值后得到一个值的构造。参见：[01-basics.md](zh/01-basics.md)

### Factory Pattern (工厂模式)
一种不指定确切类、而把实例化委托给子类或参数的对象创建模式。参见：[13-patterns.md](zh/13-patterns.md)

### Fiber (纤程)
一种类协程的轻量执行单元。LuaJIT 没有原生的纤程，由协程承担这一角色。参见：[08-coroutines.md](zh/08-coroutines.md)

### Flatten (展平)
把嵌套的表压缩为单层。常见于数据处理流水线。参见：[04-tables.md](zh/04-tables.md)

### Garbage Collection (垃圾回收，GC)
自动回收已不再被使用的对象所占内存的内存管理机制。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Generator (生成器)
按需产生一系列值的函数，通常借助协程实现。参见：[08-coroutines.md](zh/08-coroutines.md)

### Global Environment (全局环境)
存放全局变量的默认表。在 Lua 5.1+ 中名为 `_G`，在 5.2+ 中则是 `_ENV`。参见：[01-basics.md](zh/01-basics.md)

### Hash Table (哈希表)
使用哈希函数把键映射到值的数据结构。Lua 表对非连续键使用哈希表。参见：[04-tables.md](zh/04-tables.md)

### Hierarchical State Machine (层次化状态机)
一种 FSM，其中状态可以包含子状态，从而形成树状结构。在保持清晰分层的同时实现复杂行为。参见：[23-advanced/fsm-advanced/](lua-mastery-roadmap/23-advanced/fsm-advanced/)

### Hot Reload (热重载)
在不重启运行中系统的情况下替换代码或配置。Lua 的 load() 函数可以实现这一点。参见：[28-advanced/deployment-patterns/](lua-mastery-roadmap/28-advanced/deployment-patterns/)

### Hot Path (热路径)
执行频繁的代码段，性能优化在这里收益最大。参见：[12-performance.md](zh/12-performance.md)

### Identity (身份)
一个表在内存中的唯一引用。两个内容相同的不同表具有不同的身份。参见：[04-tables.md](zh/04-tables.md)

### Immediate vs Deferred (立即求值与延迟求值)
在立即（急切）处理数据与延迟（惰性）处理数据之间的一种设计选择。Lua 通常采用立即求值。参见：[03-functions.md](zh/03-functions.md)

### Invariant (不变式)
在整个执行过程中必须始终成立的条件。用于循环和数据结构操作。参见：[02-control-flow.md](zh/02-control-flow.md)

### IoC (控制反转)
一种反转控制流的原则——由框架调用用户代码，而不是相反。参见：[06-modules.md](zh/06-modules.md)

### Iterator (迭代器)
从集合中依次返回元素的函数。Lua 内置了 `pairs` 和 `ipairs` 两个迭代器。参见：[02-control-flow.md](zh/02-control-flow.md)

### Lazy Evaluation (惰性求值)
把计算推迟到真正需要结果时才进行。Lua 是急切求值的，但基于协程的生成器可以模拟惰性求值。参见：[08-coroutines.md](zh/08-coroutines.md)

### Literal (字面量)
直接写在代码里的值（例如 `42`、`"hello"`、`true`）。参见：[01-basics.md](zh/01-basics.md)

### LuaJIT
带扩展的 Lua 5.1 JIT 编译实现。提供用于 C 互操作的 FFI，性能提升显著。参见：[12-performance.md](zh/12-performance.md)

### Macro (宏)
一种代码转换形式。Lua 没有 C 风格的宏，但使用 `string.gsub` 和 load/eval 可以达到类似效果。参见：[03-functions.md](zh/03-functions.md)

### Map/Filter/Reduce (映射/过滤/归约)
函数式编程操作：转换元素（map）、筛选元素（filter）、累积结果（reduce）。参见：[24-advanced/data-pipeline/](lua-mastery-roadmap/24-advanced/data-pipeline/)

### Memory Profiling (内存分析)
测量并分析内存使用模式，以发现泄漏并优化内存分配。参见：[27-advanced/memory-management/](lua-mastery-roadmap/27-advanced/memory-management/)

### Message Passing (消息传递)
并发进程之间通过发送和接收消息进行的通信。是参与者模型和 CSP 的核心。参见：[25-advanced/concurrency-patterns/](lua-mastery-roadmap/25-advanced/concurrency-patterns/)

### Memoization (记忆化)
缓存函数结果以避免重复计算的一种优化技术。参见：[03-functions.md](zh/03-functions.md)

### Metamethod (元方法)
元表中为某个特定操作（索引、算术等）定义行为的函数。参见：[05-metatables.md](zh/05-metatables.md)

### Nil (空值)
Lua 表示值缺失的方式。`nil` 和 `false` 都是假值，其他一切都是真值。参见：[01-basics.md](zh/01-basics.md)

### Object (对象)
在 Lua 中，任何 table 都可以充当对象。对象通过元表和方法获得行为。参见：[05-metatables.md](zh/05-metatables.md)

### Object Pool (对象池)
一种预先分配并复用对象、以避免反复分配/释放开销的模式。参见：[21-advanced/object-pool/](lua-mastery-roadmap/21-advanced/object-pool/)

### Operator Overloading (运算符重载)
通过元方法为标准运算符（+、-、* 等）定义自定义行为。参见：[05-metatables.md](zh/05-metatables.md)

### Pattern (模式)
用于匹配文本的模板。Lua 模式使用 `%d`、`%w`、`.`、`*`、`+`、`-`（并非正则表达式）。参见：[09-standard-library.md](zh/09-standard-library.md)

### Pool (池)
一组可复用的对象，避免反复分配/释放。参见：[12-performance.md](zh/12-performance.md)

### Preprocessor (预处理器)
在执行之前对源码进行转换的代码。Lua 的 `string.gsub` 和 `load` 可以充当轻量级预处理器。参见：[06-modules.md](zh/06-modules.md)

### Priority Queue (优先队列)
按优先级而非插入顺序出队的数据结构。参见：[12-performance.md](zh/12-performance.md)

### Promise
未来某个值的占位符。Lua 没有原生的 Promise；协程和回调承担着类似角色。参见：[08-coroutines.md](zh/08-coroutines.md)

### Publish/Subscribe (发布/订阅)
一种消息传递模式：发布者向主题发送消息，订阅者接收自己感兴趣的主题的消息。参见：[22-advanced/pub-sub-system/](lua-mastery-roadmap/22-advanced/pub-sub-system/)

### Proxy (代理)
控制对另一个对象访问的中间层。用于日志记录、校验和只读保护。参见：[05-metatables.md](zh/05-metatables.md)

### Queue (队列)
一种 FIFO（先进先出）数据结构。使用带头尾索引的表实现。参见：[12-performance.md](zh/12-performance.md)

### Recursion (递归)
函数调用自身。Lua 支持真正的尾调用：处于尾位置的调用会复用栈帧，所以尾递归不会让栈增长。而 `return 1 + f(x)` 不在尾位置，栈仍会增长。参见：[03-functions.md](zh/03-functions.md)

### Reference Type (引用类型)
赋值时复制引用而非数据的类型。table、函数、用户数据和线程都是引用类型。参见：[01-basics.md](zh/01-basics.md)

### Reflection (反射)
在运行时检查并修改代码结构。`debug` 库提供了 Lua 的反射能力。参见：[debugging-guide.md](zh/debugging-guide.md)

### Sandboxing (沙箱)
限制脚本对危险函数和资源的访问。运行不受信任的代码时必不可少。参见：[14-lua-in-production.md](zh/14-lua-in-production.md)

### Sentinel (哨兵值)
用作标记的唯一值，用来区分「无值」与合法值。参见：[04-tables.md](zh/04-tables.md)

### Stack Trace (调用栈跟踪)
在某个特定位置对调用栈的快照，显示函数名和行号。用于调试。参见：[debugging-guide.md](zh/debugging-guide.md)

### Tail Call (尾调用)
处于尾位置的函数调用，可以被优化为复用当前的栈帧。参见：[03-functions.md](zh/03-functions.md)

### Thread (线程)
在 Lua 中指的是协程（而不是操作系统线程）。Lua 协程是协作式的，而且非常轻量。参见：[08-coroutines.md](zh/08-coroutines.md)

### Truthiness (真值)
Lua 的布尔求值规则：只有 `false` 和 `nil` 是假值；`0`、`""`、`{}` 都是真值。参见：[01-basics.md](zh/01-basics.md)

### Transducer (转换器)
一种可组合的转换，能在不创建中间集合的前提下组合映射与过滤。参见：[24-advanced/data-pipeline/](lua-mastery-roadmap/24-advanced/data-pipeline/)

### Transition Guard (转移守卫)
在 FSM 中，一次状态转移发生之前必须为真的条件。参见：[23-advanced/fsm-advanced/](lua-mastery-roadmap/23-advanced/fsm-advanced/)

### Type Checking (类型检查)
验证一个值是否与期望的类型匹配。可通过 `type()` 函数或断言模式来完成。参见：[01-basics.md](zh/01-basics.md)

### Value Type (值类型)
赋值时复制值而非引用的类型。数字、布尔值和 nil 属于值类型。参见：[01-basics.md](zh/01-basics.md)

### Variable (变量)
用于存储值的具名存储位置。可以是局部变量（作用域受限），也可以是全局变量（在整个环境内有效）。参见：[01-basics.md](zh/01-basics.md)

### Weak Reference (弱引用)
不会阻止垃圾回收的引用。通过元表中的 `__mode` 实现。参见：[10-lua-internals.md](zh/10-lua-internals.md)

### Yield (让出)
挂起协程的执行，并把控制权交还调用方。参见：[08-coroutines.md](zh/08-coroutines.md)

## 交叉引用

- **Chapter 01**：基础、类型、变量
- **Chapter 03**：函数、闭包、上值
- **Chapter 04**：表、数组、哈希部分
- **Chapter 05**：元表、元方法、原型
- **Chapter 06**：模块、环境
- **Chapter 08**：协程、协作式多任务
- **Chapter 10**：VM、字节码、GC 内部机制
- **Chapter 11**：C API、用户数据、FFI
- **Chapter 12**：性能、优化、JIT
- **Chapter 13**：设计模式、ECS
- **Chapter 14**：生产环境、沙箱、部署
