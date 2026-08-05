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
  - title: "Rich Autofill"
    details: "Auto-fill your parameter names — <code>a01: type</code> begone!"
    link: /getting-started/quick-start#connect-a-listener
  - title: "Strict Typing"
    details: "Fully strictly typed for the New Luau Type Solver."
    link: https://devforum.roblox.com/t/general-release-luau’s-new-type-solver/4084991
  - title: "Deferred Mutations"
    details: "Get predictable behavior and prevent edge case bugs."
    link: /api-reference/deferred-mutations
  - title: "High Performance"
    details: "More efficient than engine APIs by working in pure Luau."
    link: /additional-info/performance
---

<!-- markdownlint-disable-file MD041 -->

## 1. Richer Autofill

NamedSignal introduces named parameters, providing more semantic information than just the type.

Simply use Luau's function type syntax to define names!

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

## 2. Strict Typechecking

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

## 3. Deferred Mutations

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

## 4. Performance

NamedSignal is optimised to perform well in every use case, from light signals to extremes with thousands of connections.

With multiple connections, performance is greatly improved using a minimized resumption dispatcher (also known as 'spinning threadloop'), resulting in **600%+ speedup** with 10 connections.

Read more about optimizations and details on the [dedicated page](/additional-info/performance).

## Interested?

Check out the [Introduction](/getting-started/introduction) and comparisons to other libraries, or get straight into [Installation](/getting-started/installation).

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
		<p style="margin-bottom: 0.1rem; margin-top: 0; font-size: 1.5em;"><b>SCDS</b></p>
		<p style="margin-bottom: 0; margin-top: 0.1rem; color: grey">No AI usage.</p>
	</div>
</div>
