<!-- markdownlint-disable-file MD024 MD033 MD034 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.2] - 2026-07-22

### Fixed

- Fixed a regression in v2.3.x where immediate-mode disconnections did not stop the listener from being dispatched.

### Changed

- Improved performance when dispatching signals with no connections.

## [2.3.1] - 2026-07-21

### Removed

- Removed the internal `SIGNAL_BEHAVIOR` flag that toggled `task.spawn` vs `task.defer`.
  - Flags are considered unstable and subject to change, this flag conflicted with internal dispatching and caused an infinite loop which froze the program when enabled.
  - The edge cases this was originally meant to address are now handled by deferred mutations, a much more comprehensive and performant mechanism — making the flag redundant.
  - This does not affect your ability to defer other operations (e.g. functions in listeners); only the internal spawn/defer toggle has been removed.

## [2.3.0] - 2026-07-21

Changes since v2.2.0:

### Changed

- Maintenance: Refactored Types module. Shouldn't change type behavior in public APIs, but may improve inference speed.
- Config: The default `ERROR_INFO_MODE` has been changed to `"Full"` (always prefer `task.spawn`) due to possible C-side issues with `coroutine.resume`.
  - You may opt back into a different mode if you require the additional performance and are aware of the risks.
- Performance: Greatly improved non-yielding fire performance by switching to a more efficient dispatching technique with minimized thread resumptions.
  - Signals with only one connection may be slightly slower, but benefits should be visible with two or more connections.
  <br><br>
  
  From internal benchmarking:

  | Connection Count | % Improvement from v2.2.0 |
  | ---------------- | ------------------------- |
  | 1                | -18.8% (Slower)           |
  | 2                | +49.2% (Faster)           |
  | 5                | +258.6% (Faster)          |
  | 10               | +535.1% (Faster)          |
  | 50               | +1523.2% (Faster)         |

### Fixed

- Fixed a missing type export for `WrapConnection` in the main module.

## [2.3.0-rc.1] - 2026-07-20

### Changed

- Maintenance: Refactored Types module. Shouldn't change type behavior in public APIs, but may improve inference speed.
- Config: The default `ERROR_INFO_MODE` has been changed to `"Full"` (always prefer `task.spawn`) due to possible C-side issues with `coroutine.resume`.
  - You may opt back into a different mode if you require the additional performance and are aware of the risks.
- Performance: Greatly improved non-yielding fire performance by switching to a more efficient dispatching technique with minimized thread resumptions.
  - Signals with only one connection may be slightly slower, but benefits should be visible with two or more connections.
  <br><br>
  
  From internal benchmarking:

  | Connection Count | % Improvement from v2.2.0 |
  | ---------------- | ------------------------- |
  | 1                | -18.8% (Slower)           |
  | 2                | +49.2% (Faster)           |
  | 5                | +258.6% (Faster)          |
  | 10               | +535.1% (Faster)          |
  | 50               | +1523.2% (Faster)         |

## [2.2.0] - 2026-07-17

Changes since v2.1.7:

### Fixed

- Fixed a class of iterator invalidation edge cases involving connections made after immediate-mode 'Now' disconnections on the active node.
  - Note: Those who've not used deferred mutation opt-outs were not impacted.
- Fixed an iterator invalidation edge case when `DisconnectNow()` was used on a tail connection before `DisconnectAllNow()`.

### Added

- Added new method `Signal:GetConnections()`, which returns an array of active connections on the signal, ordered from oldest to newest.
- `Connection:DestroyNow()` is now supported.

## [2.2.0-rc.2] - 2026-07-15

### Fixed

- Fixed an iterator invalidation edge case when `DisconnectNow()` was used on a tail connection before `DisconnectAllNow()`.

## [2.2.0-rc.1] - 2026-07-14

### Fixed

- Fixed a class of iterator invalidation edge cases involving connections made after immediate-mode 'Now' disconnections on the active node.
  - Note: Those who've not used deferred mutation opt-outs were not impacted.

### Added

- Added new method `Signal:GetConnections()`, which returns an array of active connections on the signal, ordered from oldest to newest.
- `Connection:DestroyNow()` is now supported.

## [2.1.7] - 2026-07-12

### Fixed

- Changed the approach on how we handled the iterator invalidation bug where immediate-mode 'Now' connections made within Once connections were missed in the same dispatch cycle.
  - This fixes the behavior of `FireNow` in such cases.
- Fixed the `Connection` type not having the default signature in the exported public type.

## [2.1.6] - 2026-07-12 [YANKED]

### Fixed

- Changed the approach on how the iterator invalidation bug was handled in previous release. `FireNow` should work as expected in such cases.
- Fixed the `Connection` type not having the default signature in the exported public type.

## [2.1.5] - 2026-07-12

### Fixed

- Fixed an edge-case iterator invalidation bug involving immediate-mode 'Now' connections made within Once connections.

## [2.1.4] - 2026-07-07

### Fixes

- Uninstantiated generic from `Signal.new()` is now handled properly. Previously, the signature was not being sanitized in all cases.

## [2.1.3] - 2026-06-24

Hello again, this release is mostly just some codebase maintenance and cleaning up.

### Added

- Minor documentation improvements.
  - Improved guidance on how to use `wally-package-types` during installation.
  - Added changelogs, available at the project root and on the documentation website.
  - Added [Function `coroutine.finally(thread, callback)` to Future Considerations](https://personal.averlyst.dev/NamedSignal/additional-info/future-considerations#function-coroutine-finally-thread-callback).

### Changes

- Codebase cleanup and workflow improvements.
- I've changed my GitHub username, however I've taken care to prevent hijacking and to redirect all URLs.
  - Repository has been moved to https://github.com/averlyst/NamedSignal — GitHub redirects these automatically.
  - Documentation has been moved https://personal.averlyst.dev/NamedSignal — Old links will lead to a redirection page!

## [2.1.2] - 2026-06-03

### Fixes

Fixed wally installation once more, `default.project.json` wasn't getting included.

## [2.1.1] - 2026-06-02

### Fixes

Fix `GenericSignal` unintentionally still using UDTFs in Connection type with new `GenericConnection` type.

See the [API Reference](https://personal.averlyst.dev/NamedSignal/api-reference/api-overview#genericconnection-type-usage) for usage information.

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

- Rewrote much of the [Introduction](https://personal.averlyst.dev/NamedSignal/getting-started/introduction) documentation page, with much more detailed comparisons between BindableEvents and other popular signal libraries.
- Added the ['Future Considerations'](https://personal.averlyst.dev/NamedSignal/additional-info/future-considerations) documentation page, which goes over some notable Luau RFCs and how NamedSignal might evolve if they were implemented.
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
- [**Added -Now suffixed method equivalents**](https://personal.averlyst.dev/NamedSignal/api-reference/deferred-mutations#the-ability-to-opt-out) to most deferred APIs to bypass deferred mutations.

### Minor Additions

- Added `Connection:Reconnect()`, which reconnects the connection back to the end of the Signal.
- Added the `GenericSignal` type, which uses pure generics instead of UDTFs to workaround unserializable types.

### Removed APIs

- Removed `bypassReentrancy` parameters from functions that had them in favor of the new -Now suffixed methods.

### Other Changes

- No longer a Class 3 Signal under Gohan's Certification, see my [reasoning for doing so](https://personal.averlyst.dev/NamedSignal/additional-info/gohans-certification#not-quite-to-spec).
- [Documentation](https://personal.averlyst.dev/NamedSignal/) has been completely rewritten using VitePress, new benchmarks are still a work in progress.
- Slightly improve the performance of non-yielding dispatch by implementing a "fast" cache as a local variable.

## [1.2.1] - 2026-02-11

Removed monotonic connection counters, as they were no longer necessary with deferred mutations

## [1.2.0] - 2026-02-10

Comply with [GohanDucis Class 3 signal certification](https://devforum.roblox.com/t/signal-certifications-classes-guide/4263792).

## [1.1.0] - 2026-02-09

Prevent connections made during invocation from being fired (with minimal impact to performance).

## [1.0.0] - 2026-02-08

Minor code cleanup and type improvements, add new benchmarks and wally install.

Bumped version to major 1 in accordance with Semantic Versioning 2.0,0, indicating public release and stability guarantee.

## [0.1.0] - 2026-02-07

Initial release of NamedSignal

[2.3.2]: https://github.com/averlyst/NamedSignal/compare/v2.3.1...v2.3.2
[2.3.1]: https://github.com/averlyst/NamedSignal/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/averlyst/NamedSignal/compare/v2.2.2...v2.3.0
[2.3.0-rc.1]: https://github.com/averlyst/NamedSignal/compare/v2.2.0...v2.3.0-rc.1
[2.2.0]: https://github.com/averlyst/NamedSignal/compare/v2.1.7...v2.2.0
[2.2.0-rc.2]: https://github.com/averlyst/NamedSignal/compare/v2.1.7-rc.1...v2.2.0-rc.2
[2.2.0-rc.1]: https://github.com/averlyst/NamedSignal/compare/v2.1.7...v2.2.0-rc.1
[2.1.7]: https://github.com/averlyst/NamedSignal/compare/v2.1.6...v2.1.7
[2.1.6]: https://github.com/averlyst/NamedSignal/compare/v2.1.5...v2.1.6
[2.1.5]: https://github.com/averlyst/NamedSignal/compare/v2.1.4...v2.1.5
[2.1.4]: https://github.com/averlyst/NamedSignal/compare/v2.1.3...v2.1.4
[2.1.3]: https://github.com/averlyst/NamedSignal/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/averlyst/NamedSignal/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/averlyst/NamedSignal/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/averlyst/NamedSignal/compare/v2.0.4...v2.1.0
[2.0.4]: https://github.com/averlyst/NamedSignal/compare/v2.0.0...v2.0.4
[2.0.0]: https://github.com/averlyst/NamedSignal/compare/v1.2.1...v2.0.0
[1.2.1]: https://github.com/averlyst/NamedSignal/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/averlyst/NamedSignal/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/averlyst/NamedSignal/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/averlyst/NamedSignal/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/averlyst/NamedSignal/releases/tag/v0.1.0
