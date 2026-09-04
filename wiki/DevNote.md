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
Scope.store

Store
IntentStore
ReactiveValue

commit()
effect()
listenTo()
History<State>
.ui()
```

## Core separation

```text
State   -> persistent and reactive
Effect  -> one-shot occurrence
Stream  -> external input into Store
History -> optional state snapshot timeline
```

## Internal engine

The package retains an attributed graph/subscription engine internally. Provider/reference terminology should not leak into the primary public API, examples, README, or wiki documentation.
