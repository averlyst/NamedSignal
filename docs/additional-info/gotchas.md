# Gotchas

This page collects common issues and misunderstandings within code that uses NamedSignal (and Signal libraries in general).

## Not for communicating across VMs or network

NamedSignal is a pure-Luau implementation, and as such **cannot facilitate communication between Luau VMs**, and also **cannot communicate across the network boundary**.

Roblox engine APIs should be used instead, such as the [Actor Messaging API](https://create.roblox.com/docs/scripting/multithreading#actor-messaging) or [RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent) Instance.

## Re-entrancy does not yield

Unlike other signal libraries that implement deferred mutations, NamedSignal does not yield the calling thread for re-entrant firing. See ['Not Quite to Spec'](gohans-certification#not-quite-to-spec) for detailed information and reasoning.

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

## Type complexity limits <Badge type="tip" text="Power Users" />

At the time of writing, Luau has **arbitrary limitations** in place that are intended to prevent typechecking from freezing. In certain complex codebases, this may be hit and prevent proper typing, even if it's still reasonably responsive.

To fix this, **override the following Luau FFlags**, increasing them until you no longer hit a limit:

::: code-group

```json [settings.json]
"luau-lsp.fflags": {
	"LuauSubtypingIterationLimit": "40000",
	"LuauSubtypingRecursionLimit": "200",
	"LuauTypeInferIterationLimit": "40000",
	"LuauTypeInferRecursionLimit": "330",
	"LuauTypeInferTypePackLoopLimit": "10000",
	"LuauSolverConstraintLimit": "2000",
	"LuauSolverRecursionLimit": "1000",
	"LuauSimplificationComplexityLimit": "16",
	"LuauTypeSimplificationIterationLimit": "256",
	"LuauUnifierRecursionLimit": "200",
	"LuauCheckRecursionLimit": "600",
	"LuauConstraintGeneratorRecursionLimit": "600",
	"LuauVisitRecursionLimit": "1000",
	"LuauTypeFunctionSerdeIterationLimit": "100000"
}
```

:::
