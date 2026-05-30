# Performance

This page documents the performance optimizations employed by NamedSignal.

## Optimizations

### Linked Lists for O(1) Disconnect

**Connections use [doubly linked lists](https://en.wikipedia.org/wiki/Doubly_linked_list)** to maintain order while allowing constant-time disconnections.

While they are slower to iterate than an array, they avoid the extremely expensive shifting required by arrays when disconnecting.

### Multi Thread Recycling

**Every thread created for invocation is reused** whenever possible, this cuts down on the overhead for spawning new threads.

### Dual Layer Thread Cache

Inspired by CPU cache architecture, NamedSignal implements **2 layers of thread caching**, a "fast" L1 cache (a `local` variable), and a "slow" thread pool (an array).

Accessing an upvalue is faster than indexing an array, so performance is slightly improved for non-yielding invocation.

### Reduced Resumption Overhead in Production

By default, NamedSignal uses [`coroutine.resume`](https://create.roblox.com/docs/reference/engine/libraries/coroutine#resume) in production to greatly reduce overhead when resuming threads with an efficient custom error and traceback logger, and [`task.spawn`](https://create.roblox.com/docs/reference/engine/libraries/task#spawn) in Studio for better debugging.

This behavior changes with different configurations:

- When `SIGNAL_BEHAVIOR` is set to `"Deferred"` ([`task.defer`](https://create.roblox.com/docs/reference/engine/libraries/task#defer) will always be used instead). `ERROR_INFO_MODE` is ignored in this mode.
- When `ERROR_INFO_MODE` is set to `"Full"`, `task.spawn` is always used.
- When `ERROR_INFO_MODE` is set to `"Warn"`, `coroutine.resume` with the custom logger is always used.
- When `ERROR_INFO_MODE` is set to `"None"`, `coroutine.resume` is always used, without any form of error logging.

### Avoiding The OOP API Internally

When a function that is part of the OOP interface is depended on internally, it's instead defined as a `const function`, which skips the `__index` lookup and allows the Luau compiler to perform [function inling](https://luau.org/performance/#function-inlining-and-loop-unrolling).

## Benchmarks

Benchmarks are a work in progress!

For now testing uses [Gohan's Certification](./gohans-certification)'s Speed Certification:

```txt
⚪ | Speed Certification     |  -  Server - Signal_Certifications:2020
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1965
☑ | Create         | -0.6μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Connect        | -0.7μs  | Baseline: 0.9μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Once           | -0.5μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_None      | -0.0μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_One       | +0.4μs  | Baseline: 0.4μs  ▶ {...} | Results: 0.8μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_Many      | +0.5μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.6μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_OneYield  | +0.4μs  | Baseline: 0.7μs  ▶ {...} | Results: 1.0μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Fire_ManyYield | +0.7μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | Disconnect     | -0.1μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:222
☑ | DisconnectAll  | -7.0μs  | Baseline: 8.1μs  ▶ {...} | Results: 1.1μs  ▶ {...}  -  Server - Signal_Certifications:222
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1965
✅ | Speed Certified         |  -  Server - Signal_Certifications:122
```
