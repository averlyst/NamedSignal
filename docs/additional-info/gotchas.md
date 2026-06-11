# Gotchas

This page collects common issues and misunderstandings within code that uses NamedSignal (and Signal libraries in general).

## Signals do not communicate across Luau VMs or network

NamedSignal is a pure-Luau implementation, and as such cannot facilitate communication between Luau VMs, and also cannot communicate across the network boundary. Roblox engine APIs should be used instead, such as the [Actor Messaging API](https://create.roblox.com/docs/scripting/multithreading#actor-messaging) or [RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent) Instance.

## Re-entrancy does not yield

Unlike other Signal libraries that implement deferred mutations, NamedSignal does not yield the calling thread for re-entrant firing. See ['Not Quite to Spec'](gohans-certification#not-quite-to-spec) for detailed information and reasoning.

As such, deferred mutations that immediately follow in the same listener can precede mutations made by the next listener in line to be invoked.

For example, with 2 listeners:

```luau
-- Listener #1:
	-- [!code highlight:2]
	Signal:Fire()     -- This never yields!
	Signal:Connect()  -- Queued before Listener #2 runs

-- Listener #2:
	Signal:Connect()
```

If you for some reason require the fire to yield, you can use the following:

```luau
-- Listener #1:
	-- [!code focus:3]
	-- [!code --]
	Signal:Fire()
	-- [!code ++:2]
	Signal:WaitNow() -- Waits until the end of the current invocation
	Signal:FireNow() -- Fires immediately
	Signal:Connect()
```
