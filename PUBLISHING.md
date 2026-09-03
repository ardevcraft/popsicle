# Publishing Popsicle

Current release: **3.0.0**

## 1. Validate locally

Run from the package root:

```bash
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

Run the example app as an additional integration check:

```bash
cd example
flutter pub get
flutter run
```

## 2. Verify release metadata

Confirm:

- `pubspec.yaml` version matches `CHANGELOG.md`
- README examples compile against the current public exports
- `LICENSE` and `NOTICE` are included
- repository/homepage/issue tracker/documentation URLs are correct
- screenshots referenced by `pubspec.yaml` exist
- no generated build output or platform-local files are committed

## 3. Tag the release

```bash
git add .
git commit -m "release: popsicle 3.0.0"
git tag v3.0.0
git push origin main --tags
```

Use your actual default branch if it is not `main`.

## 4. Publish

```bash
flutter pub publish
```

Review the package contents and confirm when prompted.

## 5. Wiki

The `wiki/` directory contains the Markdown pages for the 3.0 API. Copy/push them to the GitHub Wiki repository if the project uses GitHub Wiki hosting.
