# Installation

NamedSignal is available through multiple channels, such as wally and pesde, and standalone builds on GitHub.

::::: tabs

== GitHub
[Download](https://github.com/averlyst/NamedSignal/releases/latest/download/Signal.rbxm) the `Signal.rbxm` model from the [Latest Release](https://github.com/averlyst/NamedSignal/releases/latest), and place it in your desired location.

You can then require the module and use it in your codebase.

== Pesde (Recommended)

[Pesde](https://pesde.dev) is the recommended package manager to use for NamedSignal, as it supports types right out of the box.

Run the following commands in your Terminal:

```bash
pesde add averlyst/namedsignal
pesde install
```

== Wally

[Wally](https://wally.run) is the legacy industry standard, but has its shortcomings. Namely, it lacks support for type exports out the box.

Add the following to your `wally.toml` dependencies:

```toml
Signal = "nowoshire/namedsignal@^2.0.0"
```

Then run:

```bash
wally install
```

:::: tip TIP: Wally Package Types Fixer

Wally packages lose their type exports, to fix this, you can use the [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types) CLI tool.

You can install this tool with [Cargo](https://crates.io/):

```bash
cargo install wally-package-types
```

::: warning IMPORTANT
Do not install `wally-package-types` using other toolchain managers, you will likely run into issues with modern Luau syntax being unsupported.
Use Cargo to ensure dependencies are up to date for proper functionality.
:::

After installing packages, run:

```bash
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
```

See the README.md file in [JohnnyMorganz's repository](https://github.com/JohnnyMorganz/wally-package-types) for more information about this tool.

::::

== Rojo (From Source)

If you prefer, you can build NamedSignal directly from source using Rojo.

```bash
git clone https://github.com/averlyst/NamedSignal.git
cd NamedSignal
rojo build --output "Signal.rbxm"
```

Then insert the built `Signal.rbxm` into your desired location.

:::::
