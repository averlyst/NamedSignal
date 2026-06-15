<!-- markdownlint-disable-file MD033 MD024 -->

# Changelogs

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.2] - 2026-06-03

### Fixes

Fixed wally installation once more, `default.project.json` wasn't getting included.

## [2.1.1] - 2026-06-02

### Fixes

Fix `GenericSignal` unintentionally still using UDTFs in Connection type with new `GenericConnection` type.

See the [API Reference](https://nowoshire.github.io/NamedSignal/api-reference/api-overview#genericconnection-type-usage) for usage information.

## [2.1.0] - 2026-05-31

Back again with more improvements!

### Additions

- Added a new interface constructor `Signal.wrap(RBXScriptSignal)` and `WrapSignal<RBXScriptSignal>` type.
  - Signatures can be conveniently inferred from the given RBXScriptSignal when available. Example:

  ```lua
  local heartbeatEvent = Signal.wrap(game:GetService("RunService").Heartbeat)
  heartbeatEvent:Connect(function(deltaTime: number)
  	print(`deltaTime: {deltaTime}`)
  end)
  ```

### Improvements

- `Signal:Wait()` and `Signal:WaitNow()` can now be safely resumed externally without leaving the internal connection active.
- Dead `:Wait()`s where the event resumed but the thread is not resumable no longer produces errors.
- Improved the performance of dispatch in production by using `coroutine.resume` with an error and traceback logger, while keeping debugging benefits of `task.spawn` in Roblox Studio.
  - With this, `USE_TASK_LIBRARY` has been replaced with `ERROR_INFO_MODE`, which lets you decide between performance and error information, set to `"Auto"` by default.
- Improve argument packing/unpacking performance.

### Documentation

- Rewrote much of the [Introduction](https://nowoshire.github.io/NamedSignal/getting-started/introduction) documentation page, with much more detailed comparisons between BindableEvents and other popular signal libraries.
- Added the ['Future Considerations'](https://nowoshire.github.io/NamedSignal/additional-info/future-considerations) documentation page, which goes over some notable Luau RFCs and how NamedSignal might evolve if they were implemented.
- Minor cleanup across a few other documentation pages.

### Other Changes

- `wally.toml` has been moved back to the project root, the `wally` module will no longer appear in builds.
- Minor internal refactoring.

## [2.0.4] - 2026-04-17

Fix instance name and wally installation.

## [2.0.0] - 2026-04-16

After much wait, NamedSignal v2.0.0 is here!

### Major Changes

- Deferred mutations have been completely reworked and is now much more comprehensive and completely yieldless <small>(even `Signal:Fire()`!)</small>.
- [**Added -Now suffixed method equivalents**](https://Nowoshire.github.io/NamedSignal/api-reference/deferred-mutations#the-ability-to-opt-out) to most deferred APIs to bypass deferred mutations.

### Minor Additions

- Added `Connection:Reconnect()`, which reconnects the connection back to the end of the Signal.
- Added the `GenericSignal` type, which uses pure generics instead of UDTFs to workaround unserializable types.

### Removed APIs

- Removed `bypassReentrancy` parameters from functions that had them in favor of the new -Now suffixed methods.

### Other Changes

- No longer a Class 3 Signal under Gohan's Certification, see my [reasoning for doing so](https://Nowoshire.github.io/NamedSignal/additional-info/gohans-certification#not-quite-to-spec).
- [Documentation](https://Nowoshire.github.io/NamedSignal/) has been completely rewritten using VitePress, new benchmarks are still a work in progress.
- Slightly improve the performance of non-yielding dispatch by implementing a "fast" cache as a local variable.

## [1.2.1] - 2026-02-11

Removed monotonic connection counters, as they were no longer necessary with deferred mutations

## [1.2.0] - 2026-02-10

Comply with [GohanDucis Class 3 signal certification](https://devforum.roblox.com/t/signal-certifications-classes-guide/4263792).

## [1.1.0] - 2026-02-09

Prevent connections made during invocation from being fired (with minimal impact to performance).

## [1.0.0] - 2026-02-08

Minor code cleanup and type improvements, add new benchmarks and wally install.

Bumped version to major 1 in accordance with Semantic Versioning 2.0,0, indicating public release and stabiliity guarantee.

## [0.1.0] - 2026-02-07

Initial release of NamedSignal
