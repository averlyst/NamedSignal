<!-- markdownlint-disable-file MD033 -->

# API Overview

Overview of the NamedSignal API — the module Interface, `Signal` and `Connection` Classes, Types, and Configuration values.

## Interface

### Constructors

| Property  | Type                                                                                                            | Description                                                                          |
| --------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `.new()`  | `read <Signature>() -> (Signal<Signature>)`                                                                     | Returns a new [`Signal`](#signal).                                                   |
| `.wrap()` | <code>read \<RBXSignal>(rbxSignal: RBXSignal) -> (<a href="#wrapsignal-type">WrapSignal\<RBXSignal></a>)</code> | Returns a new [`Signal`](#signal) that fires when the given `RBXScriptSignal` fires. |

::: warning

#### `:Destroy()` ephemeral `Signal.wrap()`s

As `Signal.wrap()` makes a connection to the given `RBXScriptSignal`, not calling `:Destroy()` on temporary wraps can cause **memory leaks**!

:::

## Classes

For simplicity, the exact types used such as generics or [User-Defined Type Functions (UDTFs)](https://luau.org/types/type-functions/) are not shown in this reference.

### `Signal` {#signal}

| Member                  | Type                                                        | Description                                                                                                                       |
| ----------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `:CancelAllMutations()` | `read (self: Signal) -> ()`                                 | Cancels all deferred mutations that have not yet been processed on the `Signal`.                                                  |
| `:DisconnectAll()`      | `read (self: Signal) -> ()`                                 | Disconnects all connections from the `Signal`.                                                                                    |
| `:DisconnectAllNow()`   | `read (self: Signal) -> ()`                                 | The immediate mode equivalent of `Signal:DisconnectAll()`.                                                                        |
| `:Destroy()`            | `read (self: Signal) -> ()`                                 | Destroys the `Signal`, disconning all connections in the process, and cancelling further mutations.                               |
| `:DestroyNow()`         | `read (self: Signal) -> ()`                                 | The immediate mode equivalent of `Signal:Destroy()`.                                                                              |
| `:Connect()`            | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` and returns a [`Connection`](#connection) that represents it.                         |
| `:ConnectNow()`         | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Connect()`.                                                                              |
| `:Once()`               | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` for a single invocation and returns a [`Connection`](#connection) that represents it. |
| `:OnceNow()`            | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Once()`.                                                                                 |
| `:Wait()`               | `read (self: Signal) -> (...any)`                           | Yields the calling thread until the `Signal` fires, and returns any arguments provided by it.                                     |
| `:WaitNow()`            | `read (self: Signal) -> (...any)`                           | The immediate mode equivalent of `Signal:Wait()`.                                                                                 |
| `:Fire()`               | `read (self: Signal, ...any) -> ()`                         | Calls all connected functions and resumes all waiting threads with the given arguments.                                           |
| `:FireNow()`            | `read (self: Signal, ...any) -> ()`                         | The immediate mode equivalent of `Signal:Fire()`.                                                                                 |

::: tip

#### `:Wait()`/`:WaitNow()` can be resumed externally

Unlike common implementations of `Signal:Wait()`, NamedSignal's can be safely resumed externally with `coroutine.resume`, without causing unexpected issues.

:::

::: info

#### Immediate-mode Interruptors

`Signal:DisconnectAllNow()` and `Signal:DestroyNow()` immediately interrupt the dispatch of listeners.

:::

### `Connection` {#connection}

| Member             | Type                                           | Description                                                           |
| ------------------ | ---------------------------------------------- | --------------------------------------------------------------------- |
| `.Signal`          | <code>read <a href="#signal">Signal</a></code> | A reference to the [`Signal`](#signal) that this `Connection` is for. |
| `.Connected`       | `read boolean`                                 | Describes whether the `Connection` is active.                         |
| `.Callback`        | `read (...any) -> ()`                          | The connected function.                                               |
| `:Disconnect()`    | `read (self: Connection) -> ()`                | Disconnects the `Connection` from the `Signal`.                       |
| `:DisconnectNow()` | `read (self: Connection) -> ()`                | The immediate mode equivalent of `Connection:Disconnect()`.           |
| `:Reconnect()`     | `read (self: Connection) -> ()`                | Reconnects the `Connection` to the `Signal`.                          |
| `:ReconnectNow()`  | `read (self: Connection) -> ()`                | The immediate mode equivalent of `Connection:Reconnect()`.            |
| `:Destroy()`       | `read (self: Connection) -> ()`                | Destroys the `Connection`.                                            |

::: info

#### No `Connection:DestroyNow()`

No `Connection:DestroyNow()` method is provided, as it would cause several issues with deferred mutations.

#### `:Once()` is still once when `:Reconnect()`ing

`:Once()` connections retain their behavior when reconnected, they will disconnect again immediately on the next invocation.

:::

## Types

### `Signal<Signature>` {#signal-type}

The UDTF-managed `Signal` type. See [`Signal (Class)`](#signal) for API.

#### Usage {#signal-type-usage}

```luau
local helloEvent = Signal.new() :: Signal.Signal<(subject: "world") -> ()>
```

---

### `Connection<Signature>` {#connection-type}

The `Connection` type. See [`Connection (Class)`](#connection) for API.

#### Usage {#connection-type-usage}

```luau
local helloEvent = Signal.new() :: Signal.Signal<(subject: "world") -> ()>
local helloConnection: Signal.Connection<(subject: "world") -> ()> -- [!code highlight]

helloConnection = helloEvent:Connect(function(subject: "world")
	print(`Hello, {subject}!`)
end)
```

---

### `WrapSignal<RbxSignal>` {#wrapsignal-type}

A [`Signal`](#signal-type) type that infers a signature from the given `RBXScriptSignal` when available.

#### Usage {#wrapsignal-type-usage}

```luau
-- As a type:
type Heartbeat = Signal.WrapSignal<typeof(game:GetService("RunService").Heartbeat)> -- [!code highlight]

-- Or inferred from constructor:
local heartbeatEvent = Signal.wrap(game:GetService("RunService").Heartbeat)
```

---

### `WrapConnection<RbxSignal>` {#wrapconnection-type}

A [`Connection`](#connection-type) type that infers a signature from the given `RBXScriptSignal` when available.

#### Usage {#wrapconnection-type-usage}

```luau
local heartbeatEvent = Signal.wrap(game:GetService("RunService").Heartbeat)
local heartbeatConnection: Signal.WrapConnection<typeof(game:GetService("RunService").Heartbeat)> -- [!code highlight]

heartbeatConnection = heartbeatEvent:Connect(function(deltaTime: number)
	print(`deltaTime: {deltaTime}`)
end)
```

---

### `GenericSignal<Params...>` {#genericsignal-type}

The pure generics `Signal` type. See [`Signal (Class)`](#signal) for API.

Exists as a workaround for types that can't be serialized by UDTFs, such as recursive signals with themselves in their parameters, and for backwards compatibility with other Signal implementations.

#### Usage {#genericsignal-type-usage}

```luau
local helloEvent = Signal.new() :: Signal.GenericSignal<"world">
```

::: tip

To define both regular parameters and variadic parameters, wrap them in parentheses to form a type pack:

```lua
Signal.GenericSignal<("meow", ...":3")>
```

:::

---

### `GenericConnection<Params...>` {#genericconnection-type}

The pure generics `Connection` type. See [`Connection (Class)`](#connection) for API.

Exists as a workaround for types that can't be serialized by UDTFs, such as recursive signals with themselves in their parameters, and for backwards compatibility with other Signal implementations.

#### Usage {#genericconnection-type-usage}

```luau
local helloEvent = Signal.new() :: Signal.GenericSignal<"world">
local helloConnection: Signal.GenericConnection<"world"> -- [!code highlight]

helloConnection = helloEvent:Connect(function(subject: "world")
	print(`Hello, {subject}!`)
end)
```

## Configuration

These constants are located near the top of the script and may be configured by the developer. They are set to the recommended values by default, and should not need to be changed.

::: warning WARNING: No Stability Guarantee

These values may change or be removed as NamedSignal evolves, you will also need to reconfigure these every update if you've overriden them.

:::

### `SIGNAL_BEHAVIOR` {#config-signal-behavior}

Controls whether event handlers are fired immediately or deferred.
`"Immediate"` is the recommended default for performance reasons.

```luau
const SIGNAL_BEHAVIOR: "Immediate" | "Deferred"
	= "Immediate"
```

### `ERROR_INFO_MODE` {#config-error-info-mode}

Controls the quality of error information provided in the output.

- `"Auto"` uses `"Full"` in Roblox Studio, and `"Warn"` in production.
- `"Full"` uses `task.spawn` when available, providing the full error traceback with jump-to functionality, at the cost of worse performance.
- `"Warn"` uses `coroutine.resume` but outputs the error message with a simplified traceback. Better performance than `"Full"`.
- `"None"` uses `coroutine.resume` but provides no error information. Best performance but not recommended for typical use.

**Has no effect when [`SIGNAL_BEHAVIOR`](#config-signal-behavior) is set to `"Deferred"`**, `"Auto"` is the recommended default.

```luau
const ERROR_INFO_MODE: "Auto" | "Full" | "Warn" | "None"
	= "Auto"
```
