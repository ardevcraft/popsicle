# Publishing Popsicle

Current release: **2.1.0**

## 1. Validate locally

Run from the package root:

```bash
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

Run the example app as an integration check:

```bash
cd example
flutter pub get
flutter run
```

The 2.1 example includes dependency injection, ReactiveValue, Store `.ui()`, IntentStore, History, streams, async state, combined async sources, and parameterized Stores.

## 2. Verify release metadata

Confirm:

- `pubspec.yaml` says `2.1.0`
- `CHANGELOG.md` starts with `2.1.0`
- README examples use `commit(...)` and `.ui()`
- `History<State>` is exported
- stream examples use Store `listenTo(...)`
- `LICENSE` and `NOTICE` are included
- repository/homepage/issue tracker/documentation URLs are correct
- screenshots referenced by `pubspec.yaml` exist
- generated build output, `.dart_tool`, and repository-local `.git` data are not included in the publish archive

## 3. Tag the release

```bash
git add .
git commit -m "release: popsicle 2.1.0"
git tag v2.1.0
git push origin main --tags
```

Use the repository's actual default branch if it is not `main`.

## 4. Publish

```bash
flutter pub publish
```

Review the package contents before confirming.

## 5. Wiki

The `wiki/` directory contains the Markdown pages for the 2.1 API. Push/copy those pages to the GitHub Wiki repository when publishing documentation updates.
