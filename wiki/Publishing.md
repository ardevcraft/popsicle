# Publishing

Before publishing a Popsicle release:

```bash
flutter pub get
flutter analyze
flutter test
flutter pub publish --dry-run
```

Then verify the package version, changelog, README, LICENSE/NOTICE, screenshots, and repository metadata.

See the root `PUBLISHING.md` for the complete checklist.
