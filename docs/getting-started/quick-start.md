# Quick Start

This guide shows the basics of using NamedSignal — creating, connecting, and firing signals.

## Require and Create

Requiring the module returns a table with a `new` constructor:

```luau
local Signal = require(path.to.module)

local helloEvent = Signal.new()
```

## Type Annotation

To utilize NamedSignal's main quality-of-life feature, **named parameters**, you should annotate the type of the Signal.

You can do this in several ways:

::: code-group

```luau [Type Annotation [:]]
local helloEvent: Signal.Signal<(subject: string) -> ()> = Signal.new()
```

```luau [Type Casting [::]]
local helloEvent = Signal.new() :: Signal.Signal<(subject: string) -> ()>
```

```luau [Turbofish<a href="#type-annotation-turbofish-fnd1" id="type-annotation-turbofish-fno1">*</a> [<<>>]]
local helloEvent = Signal.new<<(subject: string) -> ()>>()
```

:::

All three approaches achieve the same result, use whichever fits your requirements.

<sup><a href="#type-annotation-turbofish-fno1" id="type-annotation-turbofish-fnd1">[*]</a></sup> Colloquial name for [explicit type parameter instantiation](https://rfcs.luau.org/explicit-type-parameter-instantiation.html), borrowed from Rust (`::<T>`).

## Connect a Listener

Once typed, Luau can automatically fill in the connecting function for you:

```luau
local helloConnection = helloEvent:Connect(function(subject: string)
	print(`Hello, {subject}!`)
end)
```

::: tip TIP: Connection Lifecycle
`Signal:Connect()` returns a [`Connection`](../api-reference/api-overview#connection) object, which can later be used to disconnect the listener by calling `Connection:Disconnect()`.
:::

## Fire the Signal

Trigger the event by calling `Signal:Fire()` with the expected arguments:

```luau
helloEvent:Fire("world")
```

## Full Example

All together:

```luau
local Signal = require(path.to.module)

local helloEvent = Signal.new<<(subject: string) -> ()>>()

local helloConnection = helloEvent:Connect(function(subject: string)
	print(`Hello, {subject}!`)
end)

helloEvent:Fire("world")
```

And voilà! You should get the following output when running the script:

```txt
Hello, world!
```

## Going Cross-Script

The most common way of sharing signals across scripts is to place it inside a table, whether at the module-level, as a member in a class, or elsewhere:

```luau
local Module = {}

Module.fooEvent = Signal.new<<(cat: "meow") -> ()>>() -- [!code highlight]

return Module
```

Other scripts can then access the created event by requiring the module that contains it:

```luau
local Module = require(path.to.module)

Module.fooEvent:Connect(function(cat: "meow")
	print(cat)
end)
```
