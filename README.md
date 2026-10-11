# TDI · Native Liquid Glass Press Lab

Three targeted native SwiftUI hypotheses for a compelling physical press response. This is an optical research experiment, **not** a claim to reproduce any third-party implementation.

## Hypotheses

| Variant | Mechanism | Prediction | Reject if |
| --- | --- | --- | --- |
| **SYSTEM** | One button with `.regular.interactive()`, no authored press animation | Native touch response alone creates a legible, organic lens-like reaction | Only a generic scale/bounce with insufficient rim depth is visible |
| **MORPH** | `GlassEffectContainer`, `glassEffectID`, `.glassEffectTransition(.matchedGeometry)`; two peripheral glass surfaces appear while pressing | Glass surfaces visually coalesce near the **fixed 274×80 pt** core, emphasizing its perimeter | Surfaces stay separate, appear as detached circles, or create visible seams |
| **MEMBRANE** | One interactive glass effect shaped by a custom `@Animatable Shape`, lateral contour deforms on press | Ends flex elastically while central glass and typography remain stable | Material fails to track deformation or reads as a mere inflated capsule |

**Controlled conditions:** dark mode; identical 274×80 pt START label; 1.2-second real XCUITest hold; fixed panel and neutral optical grid behind the material. The core must not be uniformly scaled. No colored underlay, tint or artificial glow.

## Measurement

Observe the same stages for each candidate: idle → touch-down → stable hold → release → settled. The optical grid is diagnostic background content, not a button treatment. Compare the peripheral lens, perceived depth, edge continuity, overshoot and return.

A pass in XCTest proves scenario selection and physical interaction — **not optical success**. A native recording must be inspected before judging the winner.

`SYSTEM` is the control. `MORPH` tests system material geometry transitions. `MEMBRANE` tests custom shape deformation. These are different interventions, not three parameter values for the same scale animation.

## Build locally

Requires Xcode with the iOS 26 SDK and XcodeGen:

```sh
xcodegen generate --spec project.yml
xcodebuild build-for-testing -project TDILab.xcodeproj -scheme TDILab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## Capture

The manual-only `TDI Glass Capture` workflow builds once, launches one sequential XCTest, and exports:

- Original H.264 VFR screen recording with simulator-provided timestamps.
- Separate 60 FPS playback copy, with potentially duplicated frames (never claim 60 unique captured frames).
- `frame-quality.json` listing decoded source frames and timing gaps, plus logs.

For accurate animation fidelity, prefer checking on a physical ProMotion iPhone; CI simulator video cannot prove 60 or 120 distinct frames/s. Keep Reduced Motion/Transparency in mind when interpreting system rendering.

## Acceptance

1. Native Liquid Glass, no colored fill.
2. Core and text remain in place; no uniform whole-button scaling authored by us.
3. Clear difference in response between the three mechanisms.
4. No unexpected double surfaces or seams.
5. Repeatable real holds and clean return to idle.
