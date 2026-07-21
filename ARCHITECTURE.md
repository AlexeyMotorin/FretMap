# FretMap Architecture

FretMap uses a pragmatic layered SwiftUI architecture. Dependencies point inward: feature views may use domain models and core services, while domain code does not depend on feature screens.

## Source layout

- `App`: application entry point and lifecycle integration.
- `Core`: reusable infrastructure such as audio, persistence, diagnostics, and localization.
- `Data`: bundled chord and music databases.
- `DesignSystem`: shared visual tokens, UIKit bridges, and view utilities.
- `Domain`: navigation, music-theory, tuning, chord, and saved-progression models.
- `Features`: screens and feature-specific presentation models grouped by user workflow.

## State and persistence

`AppSettingsStore` is the single observable source of user preferences. It persists a version-tolerant Codable snapshot through `SettingsPersisting`. New snapshot fields should be optional and receive a fallback during restoration so existing installations remain compatible.

## Services

Infrastructure is exposed behind narrow protocols where substitution is useful. `SettingsPersisting` supports isolated tests without `UserDefaults`; `ProgressionPlaying` defines the playback boundary. Production failures are written through unified `OSLog` categories.

## Localization

Russian source keys are stored in each `Localizable.strings` file. SwiftUI literals use bundle localization automatically, while UIKit and dynamic model titles use `L10n.string(_:)`. Run `Scripts/validate_localizations.sh` after adding or changing keys.

## Extension guidelines

1. Put music rules and serializable entities in `Domain`.
2. Put static packaged data and repositories in `Data`.
3. Keep feature-only view state beside its feature.
4. Add shared UI only after it is reused by more than one screen.
5. Preserve raw Codable values and optional migration defaults across releases.
