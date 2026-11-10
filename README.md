# CallSignal

A small, native iPhone app that reads call state and exposes it to Shortcuts.
Written in Swift and SwiftUI. No server, account, analytics, or third-party app dependencies.

**Status: complete source implementation; native build and physical-device verification pending.**
See [VALIDATION.md](VALIDATION.md) for exactly what has and has not been checked.

## Features

- **On demand:** check the current CallKit report from the app or Shortcuts.
- **Live monitor:** observe changes while CallSignal is in the foreground.
- Choose whether connected calls, held calls, ringing, and dialing count.
- Optionally show a local notification when the selected condition becomes true or false.
- See up to 100 activity entries from the current app session; clear or share them.
- Four Shortcuts actions, including a Boolean result and JSON details.
- Native dark interface, Dynamic Type, VoiceOver labels, and portrait/landscape support.
- Pure Swift detection logic with 22 unit tests and a GitHub Actions build workflow.

## The background boundary

**Live monitoring pauses when CallSignal enters the background.** It resumes with a fresh
baseline when you open it again. A brief incoming-call overlay may leave the scene inactive
but still in the foreground; monitoring remains attached in that case.

There is no claim of continuous monitoring while locked, after app switching, or after force
quitting. A normal app cannot create a reliable universal “any call started” automation trigger
by registering a CallKit observer. App Intents add actions to Shortcuts, not new call triggers.
Timers, background refresh, and declaring a VoIP background mode do not change that contract.
This app deliberately does not register background modes or make artificial calls.

When a call begins while the app is paused and is still active when you return, the current
state is visible, but no “began” notification is fabricated. Calls that start and end while
paused cannot be reconstructed. “No calls observed” describes CallKit's report at that check;
it does not promise universal coverage of every VoIP app.

## Open and run

1. Extract the project and open **CallSignal.xcodeproj** in Xcode on a Mac.
2. Use Xcode 16 or newer, with device support for the iOS version on your iPhone.
   The app's deployment target is iOS 17.0; Swift 5 language mode is intentional.
3. Select the **CallSignal** target → **Signing & Capabilities**.
4. Choose your development team and change `org.callsignal.app` to your own unique bundle ID,
   for example `com.yourname.callsignal`. Keep automatic signing enabled.
5. Connect your iPhone, select it as the run destination, and enable Developer Mode if requested.
6. Press **Run**. Open CallSignal once before searching for its actions in Shortcuts.

A personal Apple Account can be used for local device testing through Xcode's Personal Team.
Its provisioning limits still apply. The source archive is not a signed, installable IPA.
You can edit the project on Windows, but the iOS build and signing steps require Xcode on macOS.
See Apple's [developer account guide](https://developer.apple.com/help/account/basics/about-your-developer-account)
and [team setup instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html).

The simulator can display the UI. Real call detection requires a physical iPhone; simulator
queries return an explicit error rather than a misleading false result.

## Use the options

On the **Status** tab, choose **On demand** or **Live monitor**. In **Settings**, select a definition:

| Definition | Ringing / dialing | Connected | On hold |
| --- | --- | --- | --- |
| Connected, including hold | false | true | true |
| Connected, excluding hold | false | true | false |
| Ringing, dialing, or connected | true | true | true |

Ended calls never count. Multiple calls are evaluated together: ending one of two connected
calls does not make the connected condition false. “Connected, excluding hold” means only
that the CallKit hold flag is false; it does not detect whether someone is speaking or muted.

Notifications default to off. Allow notifications in Settings, then independently enable
**When the condition becomes true** and **When the condition becomes false**. These refer to
the chosen Boolean condition, not necessarily to a physical call beginning or ending.
For example, holding the last call makes an “excluding hold” condition false.

Changing definitions or modes establishes a new baseline without generating a call event.
Notification delivery remains subject to iOS notification settings and Focus.

## Shortcuts

Create a shortcut, search for **CallSignal**, and add an action:

| Action | Output / effect |
| --- | --- |
| Is On a Call | Boolean, with a per-action definition or “Use app setting” |
| Get Call State | On a call / Call on hold / Incoming call / Dialing / No calls observed |
| Get Call Details JSON | Current counts, selected definition, and observation timestamp |
| Set Live Monitoring | Opens CallSignal and selects live or on-demand mode |

For a basic conditional shortcut:

1. Add **Is On a Call**.
2. Add **If** and select the action's Boolean result as its input.
3. Add the actions you want inside **If** and **Otherwise**.
4. Invoke the shortcut manually, from a widget or Action button, or from another supported
   automation trigger. The action does not need the live-monitor option to be enabled.

The first three actions query a retained `CXCallObserver` in the app process; they do not read
a saved status or depend on the app's screen being open. They still rely on CallKit reporting
the call correctly. Test cold launches, locked invocation, and each calling app on your device.
If actions are missing, open CallSignal once and relaunch Shortcuts. Each action's execution
and lock-screen behavior is controlled by the system and invocation context.

Example JSON (illustrative, not a captured device result):

```json
{
  "activeCalls": 1,
  "connectedCalls": 1,
  "definition": "connected",
  "dialingCalls": 0,
  "heldCalls": 0,
  "matches": true,
  "observedAt": "2026-10-23T17:00:00Z",
  "ringingCalls": 0,
  "schemaVersion": 1,
  "source": "CallKit",
  "state": "On a call"
}
```

`connectedCalls` includes held calls. `activeCalls` includes every non-ended call in the
snapshot. The counts are not disjoint. `Get Call State` prioritizes a connected non-held
call, then a held call, then ringing, then dialing. Use JSON to inspect simultaneous calls.
The observation timestamp is when the app read the state, not the call's start time.

## Project structure

- `App/`: SwiftUI app, CallKit adapter, notifications, and App Intents.
- `Sources/CallSignalCore/`: platform-independent snapshot, matching, and transition logic.
- `Tests/CallSignalCoreTests/`: Swift Package unit tests for that same core source.
- `CallSignal.xcodeproj/`: ready-to-open native project with a shared app scheme.
- `docs/DEVICE_TESTING.md`: physical-device acceptance matrix.
- `.github/workflows/ci.yml`: core tests and an unsigned simulator build on a Mac runner.
- `scripts/generate_project.py`: optional standard-library-only project generator.

The Xcode app directly compiles the core source files. The Swift Package compiles the same
files for tests, avoiding duplicate implementations and external package resolution.
The Xcode app scheme does not contain an XCTest target; run the core suite with `swift test`.

## Build and test on a Mac

From the project directory:

```sh
swift test
xcodebuild -project CallSignal.xcodeproj -scheme CallSignal \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

These do not prove cellular/FaceTime/VoIP behavior. Complete the device matrix before describing
the project as device-tested. Test at least once **without the Xcode debugger attached**:
debugging can change an app's normal suspension behavior.

If you add source files outside Xcode, regenerate project membership:

```sh
python3 scripts/generate_project.py
```

Regeneration resets signing to the sample bundle ID and an empty development team.
Restore your local signing settings afterward. The icon is already included; optional
`scripts/generate_icon.py` requires Pillow only if you want to recreate it.

## Privacy

CallSignal reads CallKit state flags and in-memory call UUIDs. UUIDs are used only to reconcile
updates, never stored in the activity log or exported JSON. It does not access caller names,
phone numbers, contacts, call audio, recordings, or the Phone app's historical call database.
It requests no microphone or contacts permission.

Only mode, definition, and notification preferences are saved in this app's UserDefaults.
The activity log stays in memory, is bounded to 100 entries, and is shared only by explicit
user action. There are no app network requests or analytics. The included privacy manifest
declares the own-app UserDefaults use. Local notification permission is requested only when
the user taps **Allow notifications**.

## Publish your source after testing

Create an empty repository on your GitHub account. From this directory:

```sh
git init -b main
git add .
git commit -m "Initial CallSignal implementation"
git remote add origin https://github.com/YOUR-USERNAME/CallSignal.git
git push -u origin main
```

Replace `YOUR-USERNAME` before running. The repository has an MIT license and ignores generated
builds and Xcode user settings. GitHub Actions will run the included checks after a push; this
archive does not claim that a hosted CI run has already passed. Add your actual tested devices
and iOS versions to `docs/DEVICE_TESTING.md` before making a release. The project has not been
published to GitHub or the App Store for you.

## Apple references

- [CXCallObserver](https://developer.apple.com/documentation/callkit/cxcallobserver)
- [Call observer delegate queue](https://developer.apple.com/documentation/callkit/cxcallobserver/setdelegate(_:queue:))
- [CXCall flags](https://developer.apple.com/documentation/callkit/cxcall)
- [Creating an App Intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent)
- [iOS background execution limits](https://developer.apple.com/forums/thread/685525)
- [Required-reason APIs and privacy manifests](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)

## License

[MIT](LICENSE). Copyright 2026 CallSignal contributors.
