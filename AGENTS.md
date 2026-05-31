## Emotiva Repository Conventions

### Project Overview
- **Type**: Flutter application (`emotiva_remote`).
- **Entrypoint**: Standard Flutter application structure.

### Development Workflow & Commands
- **Run App**: Use `flutter run` for local development and debugging.
- **Run Tests**: Use `flutter test` to execute unit and widget tests.
- **Build**: Use `flutter build [ios/apk]` to generate platform-specific release artifacts.
- **Cleanup**: Use `flutter clean` before major changes or build attempts.

### Key Gotchas & Constraints (High Signal)
- **Dependency Overrides**: Due to known conflicts with newer versions, `path_provider_foundation` MUST be set to `2.5.1` in `pubspec.yaml` to ensure stable Linux builds. Do not update this version without investigation.
