# Introduction

## What are Signals?

A **Signal** is an implementation of the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern). They're used to manage communication between different scripts, promoting loose coupling and readability, resulting in a more modular and maintainable codebase.

::: tip Roblox Signals vs. Web Signals
Not to be confused with modern web development terminology, Signals here refer to **Event Emitters**, not reactive state primitives!
:::

## Why use NamedSignal?

Rather than go all out on a single selling point, NamedSignal balances **[performance](../additional-info/performance)**, **developer experience**, and **correctness**.

Most notably, we support [**named parameters**](./quick-start#type-annotation) (hence the name, *<u>Named</u>Signal*), which lends you more useful information in lambdas than the type alone.

We mirror the standard signal API, along with additional features seen in some other libraries like `Connection:Reconnect()`, so switching to NamedSignal is as simple as swapping modules out!

## Comparisons

See how NamedSignal compares to alternatives!

<!--Vs Roblox BindableEvent-->

::: details <h3>vs. [BindableEvent](https://create.roblox.com/docs/reference/engine/classes/BindableEvent)</h3> {#vs-bindableevent}

The [`BindableEvent`](https://create.roblox.com/docs/reference/engine/classes/BindableEvent) with the [`RBXScriptSignal`](https://create.roblox.com/docs/en-us/reference/engine/datatypes/RBXScriptSignal) and [`RBXScriptConnection`](https://create.roblox.com/docs/en-us/reference/engine/datatypes/RBXScriptConnection) it provides access to form the Roblox engine's implementation of the event emitter pattern.

Bindables established the convention that many signal libraries continue to follow and take inspiration from, however they suffer from **shortfalls regarding data marshalling**, and **lack modern amenities** such as type-checking.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>BindableEvent</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="2">Argument Limitations</td>
			<td><b>✅ No Limitations</b></td>
			<td><b>❌ C++ Marshalling</b></td>
		</tr>
		<tr>
			<td>Values are passed directly and untouched.<hr>Passes arguments directly, preserving tables, references, metatables, and other values.</td>
			<td>Engine deep-copies and serializes values.<hr>Mixed tables break; arbitrary keys are unsupported; cyclic tables cause an error; metatables, special objects, identities are lost, and other <a href="https://create.roblox.com/docs/scripting/events/bindable#argument-limitations">limitations</a> apply</td>
		</tr>
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b>✅ Full Support</b></td>
			<td><b>❌ No Support</b></td>
		</tr>
		<tr>
			<td>Type-checking for signal arguments in all relevant contexts, and parameter names<sup><a href="#vs-bindableevents-fnd1" id = "vs-bindableevents-fno1">[1]</a></sup> in function auto-fill.</td>
			<td>Lacks any interface to define types or parameter names.</td>
		</tr>
		<tr>
			<td rowspan="2">Object Lifecycle</td>
			<td><b>📏 Simple</b></td>
			<td><b>🍝 Messy</b></td>
		</tr>
		<tr>
			<td>Single-line creation with <code>Signal.new()</code>.<hr>Simple clean-up with convenient methods, or just 'forget and GC'.</td>
			<td>Boilerplate <code>Instance.new()</code> creation for every event.<hr>May cause memory leaks if not explicitly cleaned-up, which requires tracking connections, or destruction of the object.</td>
		</tr>
		<tr>
			<td rowspan="2">Performance</td>
			<td><b>🪶 Low overhead Luau</b></td>
			<td><b>🪨 Heavy engine overhead</b></td>
		</tr>
		<tr>
			<td>Luau implementation with several <a href="../additional-info/performance#optimizations">optimizations</a> and low overhead.</td>
			<td>C++ engine marshalling deep-copies and serializes values, degrading performance with larger payloads.</td>
		</tr>
	</tbody>
</table>

<sup><a href="#vs-bindableevents-fno1" id="vs-bindableevents-fnd1">[1]</a></sup> Parameter names are available when using the standard [`Signal`](/api-reference/api-overview#signal-type) type, which uses function signatures `(...) -> ()` to enable parameter naming.

:::

<!--Vs stravant GoodSignal, sleitnick RbxUtil Signal-->

::: details <h3>vs. [GoodSignal](https://github.com/stravant/goodsignal/tree/master)/[RbxUtil Signal](https://sleitnick.github.io/RbxUtil/api/Signal/)</h3> {#vs-goodsignal-rbxutilsignal}

Stravant's GoodSignal is the de facto standard of Roblox signal libraries, with sleitnick's RbxUtil fork being a direct extension of it.

As sleitnick's fork is extremely similar, just with some added methods and types, we'll compare with only RbxUtil Signal for simplicity.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>RbxUtil Signal</th>
		</tr>
	</thead>
	<tbody>
		<!--@include: parts/introduction-parts.md#comparison-generic-typecheck--><!---->
		<!--@include: parts/introduction-parts.md#comparison-thread-edge-cases--><!---->
		<tr>
			<td rowspan="7">Performance<sup><a href="#vs-goodsignal-rbxutilsignal-fnd1" id="vs-goodsignal-rbxutilsignal-fno1">[1]</a></sup></td>
		</tr>
		<tr>
			<td><b>Always O(1) disconnects</b></td>
			<td><b>O(n) worst-case disconnects</b></td>
		</tr>
		<tr>
			<td>Uses a <a href="https://en.wikipedia.org/wiki/Doubly_linked_list">doubly-linked list</a> structure to maintain order, while allowing for quick constant-time disconnects in all cases.</td>
			<td>Uses a singly-linked list structure that does not track the previous node, requiring iteration which degrades performance.</td>
		</tr>
		<!--@include: parts/introduction-parts.md#comparison-thread-reuse--><!---->
		<!--@include: parts/introduction-parts.md#comparison-minimized-resumption--><!---->
	</tbody>
</table>

<sup><a href="#vs-goodsignal-rbxutilsignal-fno1" id="vs-goodsignal-rbxutilsignal-fnd1">[1]</a></sup> <!--@include: parts/introduction-parts.md#footnote-performance-details-->

:::

<!--Vs FastSignal-->

::: details <h3>vs. [FastSignal](https://rblxutils.github.io/FastSignal/)</h3> {#vs-fastsignal}

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>FastSignal</th>
		</tr>
	</thead>
	<tbody>
		<!--@include: parts/introduction-parts.md#comparison-generic-typecheck--><!---->
		<!--@include: parts/introduction-parts.md#comparison-thread-edge-cases--><!---->
		<tr>
			<td rowspan="5">Performance<sup><a href="#vs-fastsignal-fnd1" id="vs-fastsignal-fno1">[1]</a></sup></td>
		</tr>
		<!--@include: parts/introduction-parts.md#comparison-thread-reuse--><!---->
		<!--@include: parts/introduction-parts.md#comparison-minimized-resumption--><!---->
	</tbody>
</table>

<sup><a href="#vs-fastsignal-fno1" id="vs-fastsignal-fnd1">[1]</a></sup> <!--@include: parts/introduction-parts.md#footnote-performance-details-->

:::

<!--Vs Signal+-->

::: details <h3>vs. [Signal+](https://alexxander.gitbook.io/signalplus)</h3> {#vs-signalplus}

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>Signal+</th>
		</tr>
	</thead>
	<tbody>
		<!--@include: parts/introduction-parts.md#comparison-generic-typecheck--><!---->
		<!--@include: parts/introduction-parts.md#comparison-thread-edge-cases--><!---->
		<tr>
			<td rowspan="3">Performance<sup><a href="#vs-signalplus-fnd1" id="vs-signalplus-fno1">[1]</a></sup></td>
		</tr>
		<!--@include: parts/introduction-parts.md#comparison-minimized-resumption--><!---->
	</tbody>
</table>

<sup><a href="#vs-signalplus-fno1" id="vs-signalplus-fnd1">[1]</a></sup> <!--@include: parts/introduction-parts.md#footnote-performance-details-->

:::

<!--Vs LemonSignal (v2.0.0)-->

::: details <h3>vs. [LemonSignal](https://data-oriented-house.github.io/LemonSignal/)</h3> {#vs-lemonsignal}

LemonSignal is a fairly competent Signal library, featuring the standard and extended signal API of most other libraries.

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>LemonSignal</th>
		</tr>
	</thead>
	<tbody>
		<!--@include: parts/introduction-parts.md#comparison-generic-typecheck--><!---->
		<tr>
			<td rowspan="3">Performance<sup><a href="#vs-lemonsignal-fnd1" id="vs-lemonsignal-fno1">[1]</a></sup></td>
		</tr>
		<!--@include: parts/introduction-parts.md#comparison-minimized-resumption--><!---->
	</tbody>
</table>

<sup><a href="#vs-lemonsignal-fno1" id="vs-lemonsignal-fnd1">[1]</a></sup> <!--@include: parts/introduction-parts.md#footnote-performance-details-->

:::
