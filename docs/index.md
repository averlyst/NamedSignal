---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "NamedSignal"
  text: ""
  tagline: "A signal implementation with a nice balance of ergonomics, performance, and features."
  image: "/square-logo.png"
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started/introduction
    - theme: alt
      text: API Reference
      link: /api-reference/api-overview

features:
  - title: "Richer Autofill"
    details: "Auto-fill your parameter names (<em><code>a01: type</code></em> begone!)"
    link: "#richer-autofill" #/getting-started/quick-start#connect-a-listener
  - title: "Strict Typechecking"
    details: "Fully strictly typed for the New Luau Type Solver."
    link: "#strict-typechecking" #https://devforum.roblox.com/t/general-release-luau’s-new-type-solver/4084991
  - title: "Deferred Mutations"
    details: "Get predictable behavior and prevent edge case bugs."
    link: "#deferred-mutations" #/api-reference/deferred-mutations
  - title: "High Performance"
    details: "DX balanced with performance; faster than engine APIs."
    link: "#performance" #/additional-info/performance
---

<!-- markdownlint-disable-file MD041 -->

## <Badge type="tip" text="1"/> Richer Autofill

Named parameters, the key feature of NamedSignal, provides more semantic information than just the type alone.

Simply use the function type syntax to define names!

```luau
local catEvent = Signal.new<<
	(name: string) -> () -- [!code highlight]
>>()

-- Parameter names and types get auto-filled!
catEvent:Connect(function(name: string)
	print(`Hi {name}!`)
end)

catEvent:Fire("Herbert") --> "Hi Herbert!"
```

## <Badge type="tip" text="2"/> Strict Typechecking

Catch bugs before they happen with Luau's strict typechecking.

```luau
local stringAdded = Signal.new<<
	(item: string) -> () -- [!code highlight]
>>()

-- [!code error:3]
-- TypeError: Expected this to be 'string', but got 'number'
stringAdded:Fire(100)
                 ^^^
```

## <Badge type="tip" text="3"/> Deferred Mutations

Defer mutations for more predictable and consistent behavior, eliminating edge-cases.

```luau
local connection: Signal.Connection

Signal:Once(function()
	connection:Disconnect() -- [!code highlight]
end)

connection = Signal:Connect(function()
	-- [!code highlight]
	-- Some really important code that needs to run every cycle!
	print("meow")
end)

Signal:Fire() --> "meow"
```

::: info Why?

Invocation is treated as sending a message to a snapshot of listeners; every listener that was connected at the time of `:Fire()` should get the message.

Have code that relies on immediate changes? There's an [escape hatch](/api-reference/deferred-mutations#the-ability-to-opt-out).

:::

Read more about deferred mutations on the [dedicated page](/api-reference/deferred-mutations).

## <Badge type="tip" text="4"/> Performance

While NamedSignal was primarily designed with DX in mind, it's also optimized to perform well in the majority of use cases: from light signals to extremes with thousands of connections.

A minimized resumption dispatcher (also sometimes known as 'spinning threadloop'), results in a **600%+ speedup** on signals with 10 connections, which along with other optimizations place NamedSignal on par with or ahead of other libraries.

Read more about optimizations and details on the [dedicated page](/additional-info/performance).

## Interested?

Check out the [introduction](/getting-started/introduction) to compare with other libraries, or get straight into [installation](/getting-started/installation).

---

<div
	align="center"
	style="display: flex; justify-content: center; align-items: center; padding-top: 3rem; gap: 1rem;"
>
	<a href="https://scds.igottic.com">
		<img
			src="/aaa-rating.png"
			alt="Synthetic Content Disclosure Score: AAA (No AI usage)"
			style="max-width:6rem;"
		/>
	</a>
	<div>
		<p style="margin-bottom: 0.6rem; margin-top: 0; font-size: 1.5rem;"><b>SCDS</b></p>
		<p style="margin-bottom: 0; margin-top: 0; color: grey"><Badge type="info" text="No AI Usage"/></p>
	</div>
</div>
<div align="center">
	<p style="color: grey">All code and documentation was written entirely by hand.</p>
</div>
