# Core Concepts

## State and UI

```text
UI = f(state)
```

Popsicle separates persistent state from one-shot effects.

```text
Store
├── emit(state)   -> persistent UI state
└── effect(value) -> one-shot UI work
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
scope.get -> access only
scope.use -> access + reactive dependency
```

## Structured state

Use `Store<State>` by default. Use `IntentStore<State, Intent>` only when explicit intent dispatch is useful.
