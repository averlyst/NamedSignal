# API Overview

Overview of the NamedSignal API — the module Interface, `Signal` and `Connection` Classes, and Types.

## Interface

### Constructors

| Property | Type                                   | Description                        |
| -------- | -------------------------------------- | ---------------------------------- |
| `.new()` | `<Signature>() -> (Signal<Signature>)` | Returns a new [`Signal`](#signal). |

## Classes

For simplicity, the exact types used (such as generics or UDTFs) are not shown in this reference.

### `Signal` {#signal}

| Member                  | Type                                                   | Description                                                                                                                       |
| ----------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `:CancelAllMutations()` | `(self: Signal) -> ()`                                 | Cancels all deferred mutations that have not yet been processed on the `Signal`.                                                  |
| `:DisconnectAll()`      | `(self: Signal) -> ()`                                 | Disconnects all connections from the `Signal`.                                                                                    |
| `:DisconnectAllNow()`   | `(self: Signal) -> ()`                                 | The immediate mode equivalent of `Signal:DisconnectAll()`.                                                                        |
| `:Destroy()`            | `(self: Signal) -> ()`                                 | Destroys the `Signal`, disconning all connections in the process, and cancelling further mutations.                               |
| `:DestroyNow()`         | `(self: Signal) -> ()`                                 | The immediate mode equivalent of `Signal:Destroy()`.                                                                              |
| `:Connect()`            | `(self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` and returns a [`Connection`](#connection) that represents it.                         |
| `:ConnectNow()`         | `(self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Connect()`.                                                                              |
| `:Once()`               | `(self: Signal, func: (...any) -> ()) -> (Connection)` | Connects the given function to the `Signal` for a single invocation and returns a [`Connection`](#connection) that represents it. |
| `:OnceNow()`            | `(self: Signal, func: (...any) -> ()) -> (Connection)` | The immediate mode equivalent of `Signal:Once()`.                                                                                 |
| `:Wait()`               | `(self: Signal) -> (...any)`                           | Yields the calling thread until the `Signal` fires, and returns any arguments provided by it.                                     |
| `:WaitNow()`            | `(self: Signal) -> (...any)`                           | The immediate mode equivalent of `Signal:Wait()`.                                                                                 |
| `:Fire()`               | `(self: Signal, ...any) -> ()`                         | Calls all connected functions and resumes all waiting threads with the given arguments.                                           |
| `:FireNow()`            | `(self: Signal, ...any) -> ()`                         | The immediate mode equivalent of `Signal:Fire()`.                                                                                 |

> [!NOTE]
> `Signal:DisconnectAllNow()` and `Signal:DestroyNow()` immediately interrupt the dispatch of listeners.

### `Connection` {#connection}

| Member             | Type                       | Description                                                           |
| ------------------ | -------------------------- | --------------------------------------------------------------------- |
| `.Signal`          | [`Signal`](#signal)        | A reference to the [`Signal`](#signal) that this `Connection` is for. |
| `.Connected`       | `boolean`                  | Describes whether the `Connection` is active.                         |
| `.Callback`        | `(...any) -> ()`           | The connected function.                                               |
| `:Disconnect()`    | `(self: Connection) -> ()` | Disconnects the `Connection` from the `Signal`.                       |
| `:DisconnectNow()` | `(self: Connection) -> ()` | The immediate mode equivalent of `Connection:Disconnect()`.           |
| `:Reconnect()`     | `(self: Connection) -> ()` | Reconnects the `Connection` to the `Signal`.                          |
| `:ReconnectNow()`  | `(self: Connection) -> ()` | The immediate mode equivalent of `Connection:Reconnect()`.            |
| `:Destroy()`       | `(self: Connection) -> ()` | Destroys the `Connection`.                                            |

> [!NOTE]
> No `Connection:DestroyNow()` is provided, as it would cause several issues with deferred mutations.

## Types

### `Signal<Signature>` {#signal-type}

The UDTF-managed `Signal` type. See [`Signal (Class)`](#signal) for API.

#### Usage {#signal-type-usage}

```luau
const helloEvent = Signal.new() :: Signal.Signal<(subject: "world") -> ()>
```

### `GenericSignal<Params...>` {#genericsignal-type}

The pure generics `Signal` type. See [`Signal (Class)`](#signal) for API.

Exists as a workaround for types that can't be serialized by UDTFs, and for backwards compatibility with other Signal implementations.

#### Usage {#genericsignal-type-usage}

```luau
const helloEvent = Signal.new() :: Signal.GenericSignal<"world">
```

### `Connection<Signature>` {#connection-type}

The `Connection` type. See [`Connection (Class)`](#connection) for API.

#### Usage {#connection-type-usage}

```luau
const helloEvent = Signal.new() :: Signal.Signal<(subject: "world") -> ()>
local helloConnection: Signal.Connection<(subject: "world") -> ()> -- [!code focus][!code highlight]

helloConnection = helloEvent:Connect(function(subject: "world")
	print(`Hello, {subject}!`)
end)
```
