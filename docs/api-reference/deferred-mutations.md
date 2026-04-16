# Deferred Mutations

This page explains what deferred mutations are, why they're used, and how it's better than immediate mutations.

## What is Re-entrancy?

Re-entrancy refers to the act of firing inside a fire — essentially, recursion.

## What is a Mutation?

A "mutation" occurs whenever you change the state of a `Signal` or a `Connection`. This happens through:

- `Signal:Connect()`
- `Signal:Once()`
- `Connection:Disconnect()` ... and other APIs.

## What is Deferring?

Deferring — not to be confused with Roblox's [`task.defer`](https://create.roblox.com/docs/reference/engine/libraries/task#defer) — refers to the scheduling of a mutation to be processed at the end of the active invocation.

There can be multiple "re-entrancy levels", and mutations on the first level are processed in order from oldest to newest. Firing during re-entrancy creates a new re-entrancy level, which prevents subsequent mutations from being processed at the wrong time.

## Core Philosophy: Snapshots

When you call `Signal:Fire()`, you are issuing a command to notify a specific group of observers. **Deferred Mutation** treats that group as a "snapshot" in time.

If a listener is disconnected *while* the Signal is firing, it still exists within the context of that specific "event". This ensures that every listener was valid at the moment of the fire gets its turn to respond.

### Predictable Execution Flow

With **immediate mutations**, a listener can effectively "cancel" the execution of listeners further down the chain by disconnecting them. This creates **order-dependent bugs** — if Listener A is connected before Listener B, A can kill B. If the order changes later, your game logic can break.

With **deferred mutations**, disconnections do not apply until after the invocation is complete, so this class of bug is completely avoided.

### Preventing Re-entrancy Chaos

If a Signal fires, and a listener then fires the same Signal again (recursion), immediate mutations would cause listeners to not be run in the exact order they were connected in, possibly causing edge case bugs.

For example, **without deferred mutations**:

```luau
signal:Connect(function(condition: boolean)
	print("Listener #1")

	if condition then
		signal:Fire(false)
	end
end)

signal:Connect(function()
	print("Listener #2")
end)

signal:Connect(function()
	print("Listener #3")
end)

signal:Fire(true)
```

...would output:

```txt
Listener #1
// [!code highlight]
Listener #1  <- Re-entry
Listener #2
Listener #3
Listener #2
Listener #3
```

...versus **with deferred mutations**:

```txt
Listener #1
Listener #2
Listener #3
// [!code highlight]
Listener #1  <- Re-entry
Listener #2
Listener #3
```

## The Ability to Opt-Out

While deferred mutations are the safest default, almost every `Signal` and `Connection` method in **NamedSignal** includes a **-Now** suffixed equivalent. These bypass the mutation queue, applying changes immediately.

### Example Use Cases

#### 1. The Emergency Abort

Use the `Signal:DestroyNow()` or `Signal:DisconnectAllNow()` method to halt a chain instantly. This is vital when a listener detects a state that makes subsequent logic dangerous or invalid.

```luau
const object = Instance.new("BoolValue")
const valueChanged = Signal.new<<(value: boolean) -> ()>>()

-- [!code focus:8]
valueChanged:Connect(function(value: boolean)
	if value then
		object:Destroy()
		-- Stop further listeners from trying to access the destroyed object!
		-- [!code highlight]
		valueChanged:DestroyNow()
	end
end)

valueChanged:Connect(function(value: boolean)
	-- This listener will error if the object is destroyed!
	object.Parent = workspace
end)

object.Changed:Connect(function(value: boolean)
	valueChanged:Fire(value)
end)

object.Value = true
```

#### 2. End of Dispatch Clean-Up

`Signal:WaitNow()` allows a listener to yield until the end of the current dispatch cycle. This lets you write cleanup logic that is guaranteed to run after all other listeners, regardless of connection order.

> [!NOTE]
> This assumes you aren't using other deferred methods that can schedule after `:WaitNow()`.

```luau
const processObject = Signal.new<<(object: Instance) -> ()>>()

-- [!code focus:6]
processObject:Connect(function(object: Instance)
	-- Yield until all other listeners have finished.
	-- [!code highlight]
	processObject:WaitNow()
	object:Destroy() -- Cleanup
end)

processObject:Connect(function(object: Instance)
	object.Name = "Debris"
end)

processObject:Fire(Instance.new("Part"))
```
