<!-- markdownlint-disable-file MD033 -->

# API Overview

Overview of the NamedSignal API — the module Interface, `Signal` and `Connection` Classes, Types, and Configuration values.

## Interface

### Constructors

| Property | Type | Description |
| - | - | - |
| `.new()` | `read <Signature>() -> (Signal<Signature>)` | Returns a new [`Signal`](#signal). |
| `.wrap()` | <code>read \<RBXSignal>(rbxSignal: RBXSignal) -> (<a href="#wrapsignal-type">WrapSignal\<RBXSignal></a>)</code> | Returns a new [`Signal`](#signal) that fires when the given `RBXScriptSignal` fires. |

> [!IMPORTANT]
>
> #### `:Destroy()` ephemeral `Signal.wrap()`s
>
> As `Signal.wrap()` makes a connection to the given `RBXScriptSignal`, not calling `:Destroy()` on temporary wraps can cause **memory leaks**!

## Classes

For simplicity, the exact types used such as generics or [User-Defined Type Functions (UDTFs)](https://luau.org/types/type-functions/) are not shown in this reference.

### `Signal` {#signal}

| Member | Type | Description |
| - | - | - |
| `:CancelAllMutations()` | `read (self: Signal) -> ()` | Cancels all deferred mutations that have not yet been processed on the `Signal`. |
| `:GetConnections()` | `read (self: Signal) -> ({Connection})` | Returns an array of active [`Connection`](#connection)s on this `Signal` ordered from oldest to newest. |
| `:DisconnectAll()` | `read (self: Signal) -> ()` | Disconnects all connections from the `Signal`. |
| `:DisconnectAllNow()` | `read (self: Signal) -> ()` | The immediate mode equivalent of `Signal:DisconnectAll()`. |
| `:Destroy()` | `read (self: Signal) -> ()` | Destroys the `Signal`, disconning all connections in the process, and cancelling further mutations. |
| `:DestroyNow()` | `read (self: Signal) -> ()` | The immediate mode equivalent of `Signal:Destroy()`. |
| `:Connect()` | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` and returns a [`Connection`](#connection) that represents it. |
| `:ConnectNow()` | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Connect()`. |
| `:Once()` | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` for a single invocation and returns a [`Connection`](#connection) that represents it. |
| `:OnceNow()` | `read (self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Once()`. |
| `:Wait()` | `read (self: Signal) -> (...any)` | Yields the calling thread until the `Signal` fires, and returns any arguments provided by it. |
| `:WaitNow()` | `read (self: Signal) -> (...any)` | The immediate mode equivalent of `Signal:Wait()`. |
| `:Fire()` | `read (self: Signal, ...any) -> ()` | Calls all connected functions and resumes all waiting threads with the given arguments. |
| `:FireNow()` | `read (self: Signal, ...any) -> ()` | The immediate mode equivalent of `Signal:Fire()`. |

::: tip

#### `:Wait()`/`:WaitNow()` can be resumed externally

Unlike common implementations of `Signal:Wait()`, NamedSignal's can be safely resumed externally, without causing unexpected issues!

:::

::: info

#### Immediate-mode Interruptors

`Signal:DisconnectAllNow()` and `Signal:DestroyNow()` immediately interrupt the dispatch of listeners.

:::

### `Connection` {#connection}

| Member | Type | Description |
| - | - | - |
| `.Signal` | <code>read <a href="#signal">Signal</a></code> | A reference to the [`Signal`](#signal) that this `Connection` is for. |
| `.Connected` | `read boolean` | Describes whether the `Connection` is active. |
| `.Callback` | `read (...any) -> ()` | The connected function. |
| `:Disconnect()` | `read (self: Connection) -> ()` | Disconnects the `Connection` from the `Signal`. |
| `:DisconnectNow()` | `read (self: Connection) -> ()` | The immediate mode equivalent of `Connection:Disconnect()`. |
| `:Reconnect()` | `read (self: Connection) -> ()` | Reconnects the `Connection` to the `Signal`. |
| `:ReconnectNow()` | `read (self: Connection) -> ()` | The immediate mode equivalent of `Connection:Reconnect()`. |
| `:Destroy()` | `read (self: Connection) -> ()` | Destroys the `Connection`. |
| `:DestroyNow()` | `read (self: Connection) -> ()` | The immediate mode equivalent of `Connection:Destroy()`. |

::: tip

#### `:Once()` is still once when `:Reconnect()`ing

`:Once()` connections **retain their behavior when reconnected**, they disconnect again on the next invocation!

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

> [!WARNING] No Stability Guarantee
> Flags are unstable and subject to change or removal.
> They are set to the recommended values by default, only change these if you know what you're doing.

### `ERROR_INFO_MODE` {#config-error-info-mode}

Controls the quality of error information provided in the output in exchange for performance.

- `"Auto"` uses `"Full"` in Roblox Studio, and `"Warn"` in production.
- `"Full"` uses `task.spawn` when available, providing the full error traceback with jump-to functionality, at the cost of worse performance.
- `"Warn"` uses `coroutine.resume` but outputs the error message with a simplified traceback. Better performance than `"Full"`.
- `"None"` uses `coroutine.resume` but provides no error information. Best performance but not recommended for typical use.

`"Full"` is the recommended default.

> [!CAUTION] Here be dragons!
> Switching to modes other than "Full" may lead to unexpected C-side issues in rare cases.
> It's strongly recommended that you do not change this unless you really need the extra performance and are aware of the risks.

```luau
const ERROR_INFO_MODE: "Auto" | "Full" | "Warn" | "None"
	= "Full"
```
