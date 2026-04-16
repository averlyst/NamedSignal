# Introduction

## What's a Signal?

A **Signal** is an implementation of the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern). It's a custom event-dispatching system used to manage communication between different scripts without tight coupling, improving code modularity, performance, and readability compared to the Roblox engine's [RBXScriptSignal](https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal) and [BindableEvents](https://create.roblox.com/docs/reference/engine/classes/BindableEvent).

## Why use this?

Signals promote event-driven, decoupled, modular code, allowing scripts to communicate without being tightly dependent on each other.

Roblox provides built-in events, but they come with limitations:

- **`BindableEvent`s are Instances** — managing them can become tedious and boilerplatey.
- **Values are serialized and deep-copied** — modifying a table in a receiving script doesn't change the table in the sending script.
- **No typechecking or autocomplete** — you'll need to memorize or waste time writing and reading documentation for your API.

> [!NOTE]
> Roblox recently announced "Signals" as part of their ["Evolving Luau OSS: Community Contributions & More!" announcement](https://devforum.roblox.com/t/evolving-luau-oss-community-contributions-more/4566806), despite its name however, it is ***not* a 'Signal' library**, and is instead a **Reactive State** implementation.

Other Signal libraries are an improvement over this, but they still have a few issues:

- **Typechecked parameters, but still unnamed** — anonymous function autofill just uses `a`-numbered parameter names (e.g `a01: type, a02: type`), so you'll still need to refer to some documentation.
  - NamedSignal improves on this by using functiontypes which allow naming parameters, for example: `(cat: "meow", dog: "woof") -> ()`. This allows for a much richer autofill experience, as names can now be autofilled!
- **Instantaneous mutations** — they can result in re-entrancy issues that lead to unexpected behavior, see [Deferred Mutations](../api-reference/deferred-mutations) for more info.
- **Improper thread recycling** — some libraries don't check if a thread can actually be re-used, which leads to silent errors or hard to diagnose resumption issues.
