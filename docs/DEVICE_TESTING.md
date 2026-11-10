# Physical-device acceptance checks

All device results below are **pending**, not inferred from unit tests or source parsing.

Record iPhone model, iOS version/build, Xcode version, call provider, region, and whether the
debugger was attached. Test without the debugger before accepting any lifecycle behavior.
Do not publish caller numbers or other people's call details with test results.

## Core scenarios

| Scenario | Expected observation | Result |
| --- | --- | --- |
| Idle, Check now | No calls observed; false for every rule | Pending |
| Incoming cellular call with CallSignal open | Ringing counts only under any-active rule | Pending |
| Answer an incoming call | Connected; true under all rules | Pending |
| Outgoing cellular call, then return to CallSignal | Dialing before answer, connected after answer; return creates baseline | Pending |
| Hold the only call | True including hold; false excluding hold | Pending |
| Resume a held call | True again when excluding hold | Pending |
| Reject or ignore an incoming call | No connected transition; any-active goes true then false if observed | Pending |
| End last connected call with CallSignal foreground | No calls observed; a true condition becomes false once | Pending |
| Call waiting / two connected or held calls | Counts remain correct; ending one does not falsely end all | Pending |
| Switch between held and active calls | Excluding-hold condition stays true when another connected non-held call remains | Pending |
| Dual-SIM or Wi-Fi Calling where available | Confirm behavior independently; no blanket compatibility assumption | Pending |
| FaceTime audio and video | Record actual CallKit coverage | Pending |
| Each third-party calling app you use | Record actual CallKit coverage; do not assume all apps expose calls | Pending |

## Modes and notifications

| Scenario | Expected behavior | Result |
| --- | --- | --- |
| On demand mode, incoming call | No live events or notifications; next explicit query shows reported state | Pending |
| Live mode, no notification permission | State and activity update; no notification request on launch | Pending |
| Allow notifications, enable true transitions | One notification when selected aggregate condition changes false → true | Pending |
| Enable false transitions | One notification on true → false; held calls follow chosen definition | Pending |
| Change rule or mode mid-call | Establish baseline; no fabricated start/end event | Pending |
| Open app in middle of an existing call | Show current state; no “became true” notification just for reopening | Pending |
| Background or lock, place and end call, reopen | Paused gap; no reconstructed events or call history | Pending |
| Background during call, reopen while call remains active | Refresh current snapshot and baseline | Pending |
| Force quit and reopen | Preferences survive; activity starts a new session; current report is queried | Pending |
| Revoke notification permission in Settings | Permission status updates on foreground; no unwanted prompts | Pending |
| Focus suppresses notifications | State detection continues in foreground; delivery follows iOS settings | Pending |

## Shortcuts

| Scenario | Expected behavior | Result |
| --- | --- | --- |
| Install, open once, search actions | All four actions discoverable | Pending |
| Is On a Call, use app setting | Boolean matches selected app rule | Pending |
| Is On a Call, explicit definition | Explicit parameter overrides app preference | Pending |
| Invoke after cold process launch during existing call | Validate actual current CallKit report; document any provider/version issue | Pending |
| Invoke with phone locked if system allows that trigger | Record whether it runs, asks for unlock, or fails; no universal promise | Pending |
| Get Call State | Human-readable state follows documented priority | Pending |
| Get Call Details JSON | Parseable JSON, correct counts, UTC observation time, no identities | Pending |
| Set Live Monitoring true / false | Opens app, selects requested mode, retains preference | Pending |
| Query in simulator | Explicit physical-device-required error | Pending |

## UI and data

- Check iPhone SE-size display, landscape, and accessibility text sizes.
- Check VoiceOver reading order, tabs, segmented control, toggles, and refresh button.
- Verify clear activity, share sheet content, and maximum 100 entries.
- Verify no microphone or contacts prompts and no network requests from the app.
- Confirm settings survive relaunch and generated app icon/launch screen render correctly.

## Test record

```text
Date:
Commit:
iPhone / iOS build:
Xcode:
Provider(s):
Region:
Debugger attached: no / yes
Passed scenarios:
Failed scenarios and reproduction:
Known limitations:
```
