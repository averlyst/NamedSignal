<!-- markdownlint-disable-file MD033 -->

# Future Considerations

NamedSignal isn't as fully rich as we would like it to be, due to typechecking limitations and other constraints of Luau.

As Luau continues to evolve, things that were previously infeasible can become trivially simple, possibly lifting limitations that we currently face in the future.

Changes to the language are proposed through a Request For Comment (RFC) process, which gives a nice peek into the future; this page documents what NamedSignal can improve on if certain RFCs were implemented.

## [Names in Type Packs](https://github.com/karl-police/rfcs/blob/patch-4/docs/type-pack-names.md)

> <small>See the [Pull Request](https://github.com/luau-lang/rfcs/pull/206)</small>

This proposal would be the most significant change in the Signal event-dispatcher scene, potentially allowing every Signal library to have named parameters if they were using generic type packs.

Currently, NamedSignal implements named parameters by using a function signature, which *does* allow naming parameters, but mutation of the signature **requires a User Defined Type Function (UDTF)**. Not only is this complicated, it's also quite **fragile in practice**, with examples being:

- Recursive signals with themselves in their parameters are unsupported and result in a type error.
- Parameter names are still lost outside of connections, meaning less useful information in `:Fire()` and similar methods.
  - This limitation could technically be resolved if another RFC is implemented — [Parameter names in `types.newfunction()`](#parameter-names-in-types-newfunction).
- Slower type inference and generally less reliable.

This proposal would allow us to solve all the issues listed above, and also allow other signal libraries to benefit from named parameters. NamedSignal would continue to maintain and improve other aspects of the library.

Additionally, a more minimal syntax for parameter naming would be achieved (without the `->()` tail), as proposed:

```luau
type Parentheses = Signal<(x: number, y: number, z: number)>

-- Or the RFC's alternative syntax
type Alternate1 = Signal<[x: number, y: number, z: number]>
type Alternate2 = Signal<[x: number], [y: number], [z: number]>
```

As a side effect, the `GenericSignal` type can be merged into the regular `Signal` type, and existing code just needs to remove the return tail or switch from `GenericSignal` to `Signal`.

## [Parameter names in `types.newfunction`](https://github.com/DavidLoveLuau/rfcs/blob/types-newfunction-named-parameters/docs/types-newfunction-named-parameters.md) {#parameter-names-in-types-newfunction}

> <small>See the [Pull Request](https://github.com/luau-lang/rfcs/pull/196)</small>

This proposal would allow UDTF-generated signatures to have properly named parameters, such as in `:Fire()` and other methods.

However, backwards compatibility concerns at the time of writing prevent this RFC from being accepted and merged, and [Names in Type Packs](#names-in-type-packs) would offer far better inference and DX. So this would unlikely be the path that NamedSignal will take.

## [Function `coroutine.finally(thread, callback)`](https://github.com/jkelaty-rbx/rfcs/blob/coroutine-finally/docs/function-coroutine-finally.md)

> <small>See the [Pull Request](https://github.com/luau-lang/rfcs/pull/187)</small>

This proposal may allow cleaner handling of threads, improving performance and reducing possibilities of memory leaks under conditions that would typically be misuse.
