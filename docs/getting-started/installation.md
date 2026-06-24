<!-- markdownlint-disable-file MD033 -->

# Installation

## From GitHub

Download the `Signal.rbxm` model from the [Latest Release](https://github.com/averlyst/NamedSignal/releases/latest), and place it in your desired location.
You can then require the module and use the API.

## With Wally

Add the following to your `wally.toml` dependencies:

```toml
Signal = "nowoshire/namedsignal@^2.0.0"
```

Then run `wally install` in your Terminal.

:::: tip TIP: Wally Package Types Fixer
Wally packages lose their type exports, to fix this, you can use the [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types) CLI tool.

You can install this tool using a toolchain manager:

::: code-group

```bash [with <a href="https://crates.io/">cargo</a>]
cargo install wally-package-types
```

```bash [with <a href="https://github.com/rojo-rbx/rokit">rokit</a>]
rokit add JohnnyMorganz/wally-package-types
```

:::

Then run:

```bash
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
```

See the README.md file in [JohnnyMorganz's repository](https://github.com/JohnnyMorganz/wally-package-types) for more information.

::::

## From Source (Building with Rojo) {#from-source}

If you prefer, you can build NamedSignal directly from source using Rojo.

```bash
git clone https://github.com/averlyst/NamedSignal.git
cd NamedSignal
rojo build --output "Signal.rbxm"
```

Then insert the built `Signal.rbxm` into your desired location.
