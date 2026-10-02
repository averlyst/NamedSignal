# Performance

This page documents the performance optimizations employed by NamedSignal.

## What We Optimize For

Unlike many libraries that boast to be "the fastest signal library", we don't make ergonomical sacrifices or use-case assumptions. That is, we attempt to balance for every possible scenario, ranging from single-digit to thousands of connections, non-yielding and yielding listeners, and more.

**We avoid micro-optimizations that hurt ergonomics**. No array-based API and indexing a number to check connection status, no FireSync/Async/Unsafe, and no caveats.

## Optimizations

### Minimized Resumption for Non-Yielding Connections

Most signal libraries cache one or more threads, however there is still a very large overhead for resumption.

We improve upon this by using a more efficient dispatching technique that **only resumes more threads when a callback yields**, leading to vastly better non-yielding invocation performance with multiple connections.

### Multi Thread Recycling

**Every thread created for invocation is reused** whenever possible, cutting down the significant overhead for churning threads.

### Dual Layer Thread Cache

We implement **2 layers of thread caching**, a 'fast' L1 cache (a `local` variable), and a slower L2 cache (an array).

Accessing an upvalue is faster than indexing or inserting into an array, thus slighting improving performance for light, repetitive, and non-yielding invocations.

### Linked Lists for O(1) Disconnect

**Connections use [doubly linked lists](https://en.wikipedia.org/wiki/Doubly_linked_list)** to maintain order while allowing constant-time disconnections.

While they are slower to iterate than an array, they avoid the extremely expensive shifting required by arrays when disconnecting.

### Avoiding The OOP API Internally

When a function that is part of the OOP interface is depended on internally, it's instead defined as a `const function`, which skips the `__index` lookup and allows the Luau compiler to perform [function inling](https://luau.org/performance/#function-inlining-and-loop-unrolling).

## Benchmarks

Benchmarks are a work in progress!

For now testing uses [Gohan's Certification](./gohans-certification)'s Speed Certification:

```txt
⚪ | Speed Certification     |  -  Server - Signal_Certifications:2023
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Create         | -0.5μs  | Baseline: 0.6μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Connect        | -0.6μs  | Baseline: 0.8μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Once           | -0.4μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_None      | -0.0μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_One       | +0.3μs  | Baseline: 0.4μs  ▶ {...} | Results: 0.6μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_Many      | -0.1μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.0μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_OneYield  | +0.2μs  | Baseline: 0.6μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_ManyYield | +0.5μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.6μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Disconnect     | -0.1μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | DisconnectAll  | -6.0μs  | Baseline: 7.2μs  ▶ {...} | Results: 1.2μs  ▶ {...}  -  Server - Signal_Certifications:225
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Speed Certified         |  -  Server - Signal_Certifications:125
```
