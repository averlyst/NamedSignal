# Quick Start

This guide shows the basics of using NamedSignal — creating, connecting, and firing signals.

## Require and Create

Requiring the module returns a table with a `new` constructor:

```luau
const Signal = require(path.to.module)

const helloEvent = Signal.new()
```

## Type Annotation

To utilize NamedSignal's main quality-of-life feature — **named parameters with full type safety** — you should annotate the type of the Signal.

You can do this in several ways:

::: code-group

```luau [Type Annotation [:]]
const helloEvent: Signal.Signal<(subject: string) -> ()> = Signal.new()
```

```luau [Type casting [::]]
const helloEvent = Signal.new() :: Signal.Signal<(subject: string) -> ()>
```

```luau ['Turbofish' [<<>>()]]
const helloEvent = Signal.new<<(subject: string) -> ()>>()
```

:::

All three approaches achieve the same result, use whichever fits your requirements.

## Connect a Listener

Once typed, Luau can automatically fill in the connecting function for you:

```luau
const helloConnection = helloEvent:Connect(function(subject: string)
	print(`Hello, {subject}!`)
end)
```

`Signal:Connect()` returns a `Connection` object, which can later be used to disconnect the listener by calling `helloConnection:Disconnect()`.

## Fire the Signal

Trigger the event by calling `Signal:Fire()` with the expected arguments:

```luau
helloEvent:Fire("world")
```

## Full Example

All together:

```luau
const Signal = require(path.to.module)

const helloEvent = Signal.new<<(subject: string) -> ()>>()

const helloConnection = helloEvent:Connect(function(subject: string)
	print(`Hello, {subject}!`)
end)

helloEvent:Fire("world")
```

And voilà! You should get the following output when running the script:

```txt
Hello, world!
```

## Going Cross-Script

The most common way of sharing Signals across scripts is to place it inside a table, whether at the module-level, as a member in a class, or elsewhere.

```luau
const Module = {}

Module.fooEvent = Signal.new<<(cat: "meow") -> ()>>() -- [!code focus][!code highlight]

return Module
```

Other scripts can then access the Signal by requiring the module that contains it.
