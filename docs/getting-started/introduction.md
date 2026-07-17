<!-- markdownlint-disable-file MD033 -->

# Introduction

## What are Signals?

A **Signal** is an implementation of the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern). They're used to manage communication between different scripts, promoting loose coupling and readability, resulting in a more modular and maintainable codebase.

::: tip Roblox Signals vs. Web Signals
Not to be confused with modern web development terminology, Signals here refer to **Event Emitters**, not reactive state primitives!
:::

## Why use NamedSignal?

NamedSignal focuses on improving developer experience by enhancing type inference. Most notably, you can **name your parameters** (hence the name) and infer signatures from RBXScriptSignals!

Additionally, a comprehensive [Deferred Mutations](../api-reference/deferred-mutations) system helps prevent re-entrancy bugs by producing consistent and predictable behavior.

The API mirrors common standard and extended Signal APIs, with additional quality-of-life features like `Connection:Reconnect()` and resume-safe `Signal:Wait()`, so switching should be rather trivial.

## Comparisons

See how NamedSignal compares to alternatives!

::: details <h3>vs. BindableEvents</h3> {#vs-bindableevents}

The [`BindableEvent`](https://create.roblox.com/docs/reference/engine/classes/BindableEvent) is the engine's implemention of the event emitter pattern, providing access to creating [`RBXScriptSignal`](https://create.roblox.com/docs/en-us/reference/engine/datatypes/RBXScriptSignal) and [`RBXScriptConnection`](https://create.roblox.com/docs/en-us/reference/engine/datatypes/RBXScriptConnection) objects.

However, as BindableEvents were introduced in **February of 2012**, it predates and lacks many modern amenities.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>BindableEvent</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b>✅ Full support</b></td>
			<td><b>❌ No support</b></td>
		</tr>
		<tr>
			<td>Enhanced typing using User Defined Type Functions, featuring support for parameter naming and automatic inference for <code>Signal.wrap</code>.</td>
			<td>Lacks any form of typechecking. Auto-fill provides no useful information without a wrapper.</td>
		</tr>
		<tr>
			<td rowspan="2">Execution Order</td>
			<td><b>✅ Predictable</b></td>
			<td><b>❌ Unintuitive</b></td>
		</tr>
		<tr>
			<td>Intuitive order: First-In, First-Out.</td>
			<td>Documented as "<b>unpredictable</b>", but <b>Last-In, First-Out</b> in practice.<sup><a href="#vs-bindableevents-footnote1">[1]</a></sup></td>
		</tr>
		<tr>
			<td rowspan="2">Object Lifecycle</td>
			<td><b>✅ Simple</b></td>
			<td><b>❌ Messy</b></td>
		</tr>
		<tr>
			<td>Easy single-line creation with <code>Signal.new()</code>.<hr>Simple clean-up with convenient methods, or just 'dereference and GC'.</td>
			<td>Boilerplate-riddled <code>Instance.new()</code> creation for every event.<hr>Clean-up requires tracking every connection or destruction of the Instance. Forgetting to do so causes memory leaks.</td>
		</tr>
		<tr>
			<td rowspan="2">Argument Limitations</td>
			<td><b>✅ None</b></td>
			<td><b>❌ Deep-copy w/ information loss</b></td>
		</tr>
		<tr>
			<td>Stays purely within Luau, arguments are passed directly to listeners without serialization.</td>
			<td>Goes through the engine, serialization deep-copies values.<hr>Downstream changes have no effect, identities are different (equality comparisons don't work), non-normal indices are stringified or lost, and other <a href="https://create.roblox.com/docs/scripting/events/bindable#argument-limitations">limitations</a> apply.</td>
		</tr>
		<tr>
			<td rowspan="2">Performance</td>
			<td><b>✅ Fast</b></td>
			<td><b>❌ Slow<sup><a href="#vs-bindableevents-footnote2">[2]</a></sup></b></td>
		</tr>
		<tr>
			<td>Efficient pure-Luau implementation with <a href="../additional-info/performance#optimizations">multiple optimizations</a>.</td>
			<td>Serialization and deep-copying for every listener is expensive and worsens rapidly with payload size, resulting in longer frametimes and higher memory usage.</td>
		</tr>
	</tbody>
</table>

<small>

<sup>[1]</sup> BindableEvent execution order tested with the following code: {#vs-bindableevents-footnote1}

```luau
local event = Instance.new("BindableEvent")
for i = 1, 10 do
	event.Event:Connect(function() print(i) end)
end
event:Fire()
--> prints 10 to 1 in reverse connection order.
```

<sup>[2]</sup> Results and ratios vary extremely by use-case (connection count, payload, and other factors), as such no single "% faster" or "% slower" figure can be provided without being misleading. {#vs-bindableevents-footnote2}

If you want numbers anyway, in a 'reasonable' scenario: 5 connections, an array with 10 numbers as a payload, BindableEvents are roughly 2.5x slower than NamedSignal. This gap widens dramatically with larger payloads.

</small>

:::

::: details <h3>vs. [GoodSignal](https://github.com/stravant/goodsignal/tree/master)/[RbxUtil Signal](https://sleitnick.github.io/RbxUtil/api/Signal/)</h3> {#vs-goodsignal-rbxutilsignal}

GoodSignal by stravant is the de facto standard of Roblox signal modules, with sleitnick's RbxUtil fork being an extension of it.

As sleitnick's fork is directly based on GoodSignal, just with some added methods and types, **comparisons are made with RbxUtil's fork** instead to avoid redundancy.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>RbxUtil Signal</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b>Extended Capabilities</b></td>
			<td><b>Standard, Generic Types</b></td>
		</tr>
		<tr>
			<td>Enhanced typing using User Defined Type Functions, featuring support for parameter naming and automatic inference for <code>Signal.wrap</code>.</td>
			<td>Uses the standard generic type packs, which lacks the ability to define parameter names.</td>
		</tr>
		<tr>
			<td rowspan="2">Dead Coroutine Handling</td>
			<td><b>✅ Safely caught and handled</b></td>
			<td><b>⚠️ No <code>coroutine.status</code> check</b></td>
		</tr>
		<tr>
			<td>This bug is safely caught and does not disrupt event dispatch.</td>
			<td><a href="https://github.com/Sleitnick/RbxUtil/blob/1616bfd99ad89f3c0d68a769b8d50c3b1b5afb87/modules/signal/init.luau#L331-L334">Does not check the status of cached threads before reuse</a>, in the unlikely event that a thread is killed while it's cached, it can remain stuck in the cache and prevent dispatching with the error "cannot spawn non-suspended coroutine".<hr>Some situations where this might occur include:<ul><li>Storing the current thread (from <code>coroutine.running</code>) of a listener, then cancelling it later.</li><li>Calling an async engine API, but implementing a manual timeout that resumes the thread. If the method errors later, the thread still gets killed. Especially dangerous as it does not output the error in console.</li></ul></td>
		</tr>
		<tr>
			<td rowspan="6">Performance<sup><a href="#vs-goodsignal-rbxutilsignal-footnote1">[1]</a></sup></td>
			<td><b><a href="https://en.wikipedia.org/wiki/Doubly_linked_list">Doubly-linked list</a> structure</b></td>
			<td><b>Singly-linked list structure</b></td>
		</tr>
		<tr>
			<td>Disconnections are always constant time.<hr>A node can be efficiently removed as the previous node can be accessed without traversing the list to find it.</td>
			<td>Disconnections are O(n) worst-case.<hr>To safely remove a node, the previous node must be updated to point to the next in line. But because the implementation uses a singly-linked list, it lacks a <code>prev</code> pointer, and <a href="https://github.com/Sleitnick/RbxUtil/blob/1616bfd99ad89f3c0d68a769b8d50c3b1b5afb87/modules/signal/init.luau#L87-L101"><b>has to traverse the list to find it</b></a>. Older connections also take longer to disconnect as they are deeper in the list.</td>
		</tr>
		<tr>
			<td><b>L1/L2 Multi-thread Reuse</b></td>
			<td><b>Single-thread Reuse</b></td>
		</tr>
		<tr>
			<td>Caches and reuses all created threads for enhanced efficiency at scale.<hr>Uses a two-layer cache, where one is a quick access upvalue that holds a single thread and is extremely quick to access, and the other is an array to hold multiple threads but is slightly slower to access.</td>
			<td>Only reuses a single thread, storing it in an upvalue. Less efficient in situations where listeners yield which requires spawning threads each time.</td>
		</tr>
		<tr>
			<td><b>Reduced Resumption Overhead in Production</b></td>
			<td><b><code>task.spawn</code> Scheduler Overhead</b></td>
		</tr>
		<tr>
			<td>In live games, uses <code>coroutine.resume</code> with error logging that produces similar info and tracebacks to normal errors, resulting in approximately 3x faster dispatch<sup><a href="#vs-goodsignal-rbxutilsignal-footnote2">[2]</a></sup>. In Roblox Studio, Uses <code>task.spawn</code> for its jump-to-source debugging capability.</td>
			<td>Always uses <code>task.spawn</code>, which goes through the task scheduler and incurs an overhead.</td>
		</tr>
	</tbody>
</table>

<small>

<sup>[1]</sup> Focuses on architectural improvements rather than micro-optimizations. Additional performance details are available at [Performance | NamedSignal](../additional-info/performance). {#vs-goodsignal-rbxutilsignal-footnote1}

<sup>[2]</sup><!--@include: parts/thread-resume-performance.md--> {#vs-goodsignal-rbxutilsignal-footnote2}

</small>

:::

::: details <h3>vs. [FastSignal](https://rblxutils.github.io/FastSignal/)/[Signal+](https://alexxander.gitbook.io/signalplus)</h3> {#vs-fastsignal-signalplus}

FastSignal and Signal+ are quite similar signal libraries, with the main difference being performance.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>FastSignal</th><th>Signal+</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b>Extended Capabilities</b></td>
			<td colspan="2"><b>Standard, Generic Types</b></td>
		</tr>
		<tr>
			<td>Enhanced typing using User Defined Type Functions, featuring support for parameter naming and automatic inference for <code>Signal.wrap</code>.</td>
			<td colspan="2">Uses the standard generic type packs, which lacks the ability to define parameter names.</td>
		</tr>
		<tr>
			<td rowspan="2">Dead Coroutine Handling</td>
			<td><b>✅ Safely caught and handled</b></td>
			<td colspan="2"><b>⚠️ No <code>coroutine.status</code> check</b></td>
		</tr>
		<tr>
			<td>This bug is safely caught and does not disrupt event dispatch.</td>
			<td colspan="2">Does not check the status of cached threads before reuse<sup><a href="#vs-fastsignal-signalplus-footnote1">[1]</a></sup>, in the unlikely event that a thread is killed while it's cached, it can remain stuck in the cache and prevent dispatching with the error "cannot spawn non-suspended coroutine".<hr>Some situations where this might occur include:<ul><li>Storing the current thread (from <code>coroutine.running</code>) of a listener, then cancelling it later.</li><li>Calling an async engine API, but implementing a manual timeout that resumes the thread. If the method errors later, the thread still gets killed. Especially dangerous as it does not output the error in console.</li></ul></td>
		</tr>
		<tr>
			<td rowspan="4">Performance<sup><a href="#vs-goodsignal-rbxutilsignal-footnote2">[2]</a></sup></td>
			<td><b>L1/L2 Multi-thread Reuse</b></td>
			<td><b>Single-thread Reuse</b></td>
			<td><b>Array Multi-thread Reuse</b></td>
		</tr>
		<tr>
			<td>Caches and reuses all created threads for enhanced efficiency at scale.<hr>Uses a two-layer cache, where one is a quick access upvalue that holds a single thread and is extremely quick to access, and the other is an array to hold multiple threads but is slightly slower to access.</td>
			<td>Only reuses a single thread, storing it in an upvalue. Less efficient in situations where listeners yield which requires spawning threads each time.</td>
			<td>Caches and reuses all created threads using an array.</td>
		</tr>
		<tr>
			<td><b>Reduced Resumption Overhead in Production</b></td>
			<td colspan="2"><b><code>task.spawn</code> Scheduler Overhead</b></td>
		</tr>
		<tr>
			<td>In live games, uses <code>coroutine.resume</code> with error logging that produces similar info and tracebacks to normal errors, resulting in approximately 3x faster dispatch<sup><a href="#vs-fastsignal-signalplus-footnote3">[3]</a></sup>. In Roblox Studio, Uses <code>task.spawn</code> for its jump-to-source debugging capability.</td>
			<td colspan="2">Always uses <code>task.spawn</code>, which goes through the task scheduler and incurs an overhead.</td>
		</tr>
	</tbody>
</table>

<small>

<sup>[1]</sup> Sources: {#vs-fastsignal-signalplus-footnote1}

[FastSignal](https://github.com/RBLXUtils/FastSignal/blob/21b1cf7b7a4e0fc38d47c3c66b3b12363099dd48/src/ReplicatedStorage/FastSignal/Immediate.lua#L64-L71), [SignalPlus](https://github.com/AlexanderLindholt/SignalPlus/blob/08a6461678983257bda6c16600d1991d411f11c3/source/init.luau#L280-L289)

<sup>[2]</sup> Focuses on architectural improvements rather than micro-optimizations. Additional performance details are available at [Performance | NamedSignal](../additional-info/performance). {#vs-goodsignal-rbxutilsignal-footnote2}

<sup>[3]</sup><!--@include: parts/thread-resume-performance.md--> {#vs-goodsignal-rbxutilsignal-footnote3}

</small>

:::

::: details <h3>vs. [LemonSignal](https://data-oriented-house.github.io/LemonSignal/)</h3> {#vs-lemonsignal}

LemonSignal is a fairly competent Signal library, featuring the standard and extended signal API of most other libraries.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>LemonSignal</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b>Extended Capabilities</b></td>
			<td colspan="2"><b>Standard, Generic Types</b></td>
		</tr>
		<tr>
			<td>Enhanced typing using User Defined Type Functions, featuring support for parameter naming and automatic inference for <code>Signal.wrap</code>.</td>
			<td colspan="2">Uses the standard generic type packs, which lacks the ability to define parameter names.</td>
		</tr>
	</tbody>
</table>

:::
