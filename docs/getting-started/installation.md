# Installation

## GitHub

Download the `Signal.rbxm` model from the [Latest Release](https://github.com/Nowoshire/NamedSignal/releases/latest), and place it in your desired location.
You can then require the module and use the API.

## Wally

Add the following to your `wally.toml` dependencies:

```toml
Signal = "nowoshire/namedsignal@^2.0.0"
```

Then run `wally install` in your Terminal.

::: tip TIP: Wally Package Types Fixer
Wally packages lose their type exports, however you can use the [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types) CLI tool to fix this, or alternatively you can manually edit the package script to re-export every type.

You can install this tool using the Rust package manager `Cargo` from [`crates.io`](https://crates.io) by running the following command in your terminal:

```bash
cargo install wally-package-types
```

See the README.md file in [JohnnyMorganz's repository](https://github.com/JohnnyMorganz/wally-package-types) for usage instructions.

:::

## Rojo (Building from source)

If you prefer, you can build NamedSignal directly from source using Rojo.

```bash
git clone https://github.com/Nowoshire/NamedSignal.git
cd NamedSignal
rojo build --output "Signal.rbxm"
```

Then insert the built `Signal.rbxm` into your desired location.
