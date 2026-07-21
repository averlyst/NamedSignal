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

### Minimized Thread Resumption for Non-Yielding Connections

Most signal libraries cache one or more threads, however there is still a very large overhead for resumption.

NamedSignal improves upon this by using a more efficient dispatching technique that only resumes more threads when a callback yields, leading to vastly better non-yielding fire performance.

### Avoiding The OOP API Internally

When a function that is part of the OOP interface is depended on internally, it's instead defined as a `const function`, which skips the `__index` lookup and allows the Luau compiler to perform [function inling](https://luau.org/performance/#function-inlining-and-loop-unrolling).

## Benchmarks

Benchmarks are a work in progress!

For now testing uses [Gohan's Certification](./gohans-certification)'s Speed Certification:

```txt
⚪ | Speed Certification     |  -  Server - Signal_Certifications:2023
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Create         | -0.6μs  | Baseline: 0.6μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Connect        | -0.6μs  | Baseline: 0.8μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Once           | -0.4μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_None      | +0.0μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_One       | +0.6μs  | Baseline: 0.4μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_Many      | -0.1μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.0μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_OneYield  | +0.5μs  | Baseline: 0.7μs  ▶ {...} | Results: 1.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_ManyYield | +0.8μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Disconnect     | -0.1μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | DisconnectAll  | -7.1μs  | Baseline: 8.2μs  ▶ {...} | Results: 1.1μs  ▶ {...}  -  Server - Signal_Certifications:225
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Speed Certified         |  -  Server - Signal_Certifications:125
```
