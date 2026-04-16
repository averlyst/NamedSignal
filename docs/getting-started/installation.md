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

## Rojo (Building from source)

If you prefer, you can build NamedSignal directly from source using Rojo.

```bash
git clone https://github.com/Nowoshire/NamedSignal.git
cd NamedSignal
rojo build --output "../Signal.rbxm"
```

Then move the built `Signal.rbxm` to your desired location.
