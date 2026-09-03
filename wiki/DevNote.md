# Development Notes

## Public design rule

Popsicle's public vocabulary should describe application intent, not the implementation engine.

Recommended API:

```text
Popsicle.inject
Popsicle.value
Popsicle.create
Popsicle.params
Scope.get
Scope.use
Store
IntentStore
ReactiveValue
.view()
```

## Internal engine

The package retains a vendored, attributed graph/subscription engine. Internal provider/reference terminology must not leak into `lib/src/api`, examples, README, or wiki documentation.

## Compatibility types

Low-level declaration classes may remain public for advanced migration/override use, but primary documentation should always lead with the `Popsicle.*` namespace.
