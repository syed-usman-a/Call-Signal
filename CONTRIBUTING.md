# Contributing

Use Xcode 16+ with a device-compatible SDK and iOS 17+ for the app. Run `swift test`
for the pure Swift core and build the app before submitting a change. New app source
files must also be included in the Xcode project (or regenerate it with the bundled script).

Changes to matching and transitions should include meaningful core tests. In particular,
preserve multiple-call handling, rule changes, baseline behavior, and end-event reconciliation.
Document actual device results when changing CallKit or lifecycle code.

Never present simulator or core-test results as proof that call detection works on an iPhone.
Keep the background limitation visible. Do not add fake audio, location, or VoIP activity
to keep the process alive. New data collection or dependencies should be explicitly discussed
and documented. Do not include caller information in issue reports.

The project uses MIT licensing. Contributions are provided under the same license.
