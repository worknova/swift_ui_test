# TDI Glass Interaction Lab

Native SwiftUI experiments for the touch-down response of a neutral Liquid Glass button.

## Scope

Three **distinct optical hypotheses**, tested using the same fixed 274 × 80 pt
START control and the same 1.2-second physical long press:

| Variant | What it tests |
| --- | --- |
| SYSTEM | Whether the built-in interactive Liquid Glass response is sufficient |
| LENS | Whether a separate peripheral glass annulus adds the required depth |
| MEMBRANE | Whether local edge deformation works while the middle remains fixed |

All variants are neutral, untinted, and without colored backing. No metronome,
sound, palettes, timers, or other interaction concepts are part of this experiment.

## Build

Requires macOS, Xcode with iOS 26 SDK, and XcodeGen.

```sh
xcodegen generate --spec project.yml
xcodebuild build-for-testing -project TDILab.xcodeproj -scheme TDILab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## Capture

The manual-only GitHub Actions workflow `TDI Glass Capture` runs one XCTest
that physically holds each variant for 1.2 seconds. The workflow publishes:

- An untouched, native H.264 variable-frame-rate recording, with real timestamps.
- A separately labeled 60 FPS review encode. It may duplicate source frames;
  this does **not** constitute real 60 FPS capture.
- `frame-quality.json` documenting real source frames and timestamp gaps.
- Build, XCTest, recording, and conversion logs.

Never use the 60 FPS review export to assert sub-frame timing, optical continuity,
or actual frame delivery on iOS Simulator.

## Acceptance criteria

1. No colored button fill or backing.
2. No uniform enlargement of the core capsule.
3. START and the central 274 × 80 pt region remain fixed.
4. Every hypothesis is distinguishable both in implementation and on-screen.
5. Each interaction is an XCUITest-injected long press, never a programmatic animation trigger.

All names, paths, test output, and commit metadata in this repository use **TDI**.
