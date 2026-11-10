# Validation status

Prepared on 2026-10-23.

## Checks performed in the authoring environment

- All 14 Swift files parsed with the tree-sitter Swift grammar without syntax errors.
  This includes the app, core, test suite, and package manifest.
- The OpenStep Xcode project parsed successfully using the `pbxproj` Python package.
- All 11 app/core Swift files are included in the app's Sources build phase.
- The asset catalog and privacy manifest are included in Resources.
- Referenced project files exist; shared scheme and workspace XML parse.
- Info and privacy property lists, asset JSON, and workflow YAML parse.
- Project regeneration produces identical project bytes.
- The bundled app icon is 1024 × 1024, opaque RGB.
- The app requests no microphone or contacts permission and registers no background modes.
- Reviewed the CallKit flags, delegate queue, App Intents integration, and foreground lifecycle.

## Not executed here

The authoring host has no Swift compiler, Xcode, Apple SDK, iOS simulator, or connected iPhone.
Consequently:

- **The 22 Swift unit tests are supplied but have not been executed.**
- **The iOS app has not been type-checked, linked, signed, or run.**
- Native UI layout and accessibility have not been visually tested in a simulator or on hardware.
- CallKit behavior, notification delivery, and Shortcuts discovery/execution are not device-verified.
- The GitHub Actions workflow is included but has not been run on a hosted runner.

Syntax and project-structure checks are not substitutes for a native build.

## Next validation on a Mac

Run the commands in README, resolve any compiler diagnostics, then complete
`docs/DEVICE_TESTING.md` on your iPhone with the Xcode debugger detached. Record actual
results before publishing a release. Confirm the calling services you care about, including
cold launches and any locked-device invocation you plan to rely on.
