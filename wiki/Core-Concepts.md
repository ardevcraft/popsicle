# Core Concepts

## State and UI

```text
UI = f(state)
```

Popsicle separates persistent state from one-shot effects:

```text
Store
├── commit(state) -> persistent UI state
└── effect(value) -> one-shot UI work
```

External streams feed the same state mechanism:

```text
Stream -> listenTo -> Store -> commit -> UI
```

History is optional:

```text
Store + History<State> -> undo / redo
```

## Declarations

```text
Popsicle.inject -> dependency
Popsicle.value  -> tiny reactive value
Popsicle.create -> Store
Popsicle.params -> parameterized Store
```

## Scope

```text
scope.get    -> access only
scope.use    -> access + reactive dependency
scope.store  -> Store instance
scope.select -> reactive state projection
```

## Structured state

Use `Store<State>` by default. Use `IntentStore<State, Intent>` when an explicit intent boundary improves the workflow.

State used with `History<State>` should be immutable.
