# Performance

This page documents the performance optimizations employed by NamedSignal, as well as benchmarks and comparisons to other Signal libraries.

## Optimizations

### Linked Lists for O(1) Disconnection

**Connections use [doubly linked lists](https://en.wikipedia.org/wiki/Doubly_linked_list)** to maintain order while allowing constant-time disconnections.

While they are slower to iterate than an array, they avoid the very expensive shifting required by arrays when disconnecting.

### Multi Thread Recycling

**Every thread created for invocation is reused** whenever possible, this cuts down on the overhead for spawning new threads.

### Dual Layer Thread Cache

Inspired by CPU cache architecture, NamedSignal implements **2 layers of thread caching**, a "fast" L1 cache (a `local` variable), and a "slow" thread pool (an array).

Accessing an upvalue is faster than indexing an array, so performance is slightly improved for non-yielding invocation.

### Maximum Coroutine Library Use

**[`task.spawn`](https://create.roblox.com/docs/reference/engine/libraries/task#spawn) is much slower (~2-4x) than [`coroutine.resume`](https://create.roblox.com/docs/reference/engine/libraries/coroutine#resume)**, so the latter is used in place of the former wherever possible.

[`task.spawn`](https://create.roblox.com/docs/reference/engine/libraries/task#spawn) is still used for listener invocation when `USE_TASK_LIBRARY` is `true` and available, as it provides error information in output.

### Avoiding The OOP API Internally

When a function that is part of the OOP interface is depended on internally, it's instead defined as a `const function`, which skips the `__index` lookup and allows the Luau compiler to perform [function inling](https://luau.org/performance/#function-inlining-and-loop-unrolling).

## Benchmarks

### Test Details

> [!NOTE]
> This benchmark only tests the standard API of most Signals, therefore many of NamedSignal's methods are not included.

**A proper benchmark is in the works!**

For now testing uses [Gohan's Certification](gohans-certification)'s Speed Certification.

### Machine Details

Specifications of the hardware and software the following benchmark results are from.

- **CPU**: AMD Ryzen 7 5700X3D 8-Core Processor (8C/16T)
- **RAM**: 32 GB 3200MT/s DDR4 (4x8G)
- **OS**: Windows 11 Pro 25H2
- **Roblox Studio**: Version 0.716.0.7160873

### Results

#### NamedSignal

```txt
⚪ | Speed Certification     |  -  Server - Signal_Certifications:2020
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1965
☑ | Create         | -0.5μs  | Baseline: 0.5μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Connect        | -0.6μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Once           | -0.4μs  | Baseline: 0.6μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_None      | +0.0μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_One       | -0.1μs  | Baseline: 0.5μs  ▶ {...} | Results: 0.4μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_Many      | +0.0μs  | Baseline: 0.3μs  ▶ {...} | Results: 0.3μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_OneYield  | -1.3μs  | Baseline: 1.9μs  ▶ {...} | Results: 0.6μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_ManyYield | -0.7μs  | Baseline: 1.2μs  ▶ {...} | Results: 0.5μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Disconnect     | -0.1μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | DisconnectAll  | -6.6μs  | Baseline: 7.7μs  ▶ {...} | Results: 1.1μs  ▶ {...}  -  Server - Signal_Certifications:222
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1965
✅ | Speed Certified         |  -  Server - Signal_Certifications:122
```
