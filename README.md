# TDI · Native Liquid Glass Press Lab

Four targeted native SwiftUI hypotheses for a compelling physical press response. This is an optical research experiment, **not** a claim to reproduce any third-party implementation.

## Hypotheses

| Variant | Mechanism | Prediction | Reject if |
| --- | --- | --- | --- |
| **SYSTEM** | One button with `.regular.interactive()`, no authored press animation | Native touch response alone creates a legible, organic lens-like reaction | Only a generic scale/bounce with insufficient rim depth is visible |
| **MORPH** | `GlassEffectContainer` with two persistent side surfaces switching `.identity` / `.regular` during press; gesture-independent glass background | Glass surfaces visually coalesce near the **fixed 274×80 pt** core, emphasizing its perimeter | Surfaces stay separate, appear as detached circles, or create visible seams |
| **MEMBRANE** | One non-interactive glass background shaped by a custom `@Animatable Shape`, lateral contour deforms on press | Ends flex elastically while central glass and typography remain stable | Material fails to track deformation or reads as a mere inflated capsule |
| **OPTICAL_LIP** | A separate continuous native-glass annulus expands around the stationary central capsule | A visible uninterrupted refracting rim appears on all four sides, while the central glass/text stay fixed | The ring breaks, renders opaque, or appears as a decorative drawn border |

**Controlled conditions:** dark mode; identical 274×80 pt START label; 1.2-second real XCUITest hold; fixed panel and neutral optical grid behind the material. The core must not be uniformly scaled. No colored underlay, tint or artificial glow.

## Measurement

Observe the same stages for each candidate: idle → touch-down → stable hold → release → settled. The optical grid is diagnostic background content, not a button treatment. Compare the peripheral lens, perceived depth, edge continuity, overshoot and return.

A pass in XCTest proves scenario selection and physical interaction — **not optical success**. A native recording must be inspected before judging the winner.

`SYSTEM` is the control. `MORPH` tests system glass blending from persistent satellite shapes (not matched-geometry transitions). `MEMBRANE` tests custom shape deformation. `OPTICAL_LIP` tests a continuous peripheral glass annulus. These are distinct geometry interventions, not scale animation presets.

## Build locally

Requires Xcode with the iOS 26 SDK and XcodeGen:

```sh
xcodegen generate --spec project.yml
xcodebuild build-for-testing -project TDILab.xcodeproj -scheme TDILab \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## CI modes

CI is **opt-in**, and the two workflows are independent. Neither starts on ordinary source commits.

- **FAST BUILD** — [`.github/workflows/tdi-fast-build.yml`](.github/workflows/tdi-fast-build.yml). Invoke via `workflow_dispatch`, or by updating `.github/tdi-build.request` on this branch. Compiles the native app **and XCTest bundle** with a generic iOS Simulator destination. Does **not** boot a device, run tests, or record video. Uploads build diagnostics and stage timings.
- **CAPTURE** — [`.github/workflows/tdi-glass-capture.yml`](.github/workflows/tdi-glass-capture.yml). Invoke via `workflow_dispatch`, or by updating `.github/tdi-capture.request`. Runs Swift/Python syntax preflight, compiles first, then boots one iPhone simulator and waits for readiness and runs four physical XCTest holds. Uploads the original H.264 **VFR** recording, raw decoded-frame timing metrics, build and XCTest logs and stage timings. Optionally encode a separate 60 FPS review with the `make_review_60fps` input; default **false** for faster CI. The review may duplicate frames and is not frame-rate evidence.

Run FAST first after source changes; run CAPTURE only after FAST succeeds, when native interaction/optics need evaluation. They intentionally use *separate fresh GitHub runners* so passing FAST does not transfer any compiled cache to CAPTURE. Do not chain them as two sequential jobs in one full capture: this would add cold-runner overhead.

The video is not a substitute for real-device evaluation. CI's simulator cannot prove 60/120 unique captured frames each second, and XCTest success does not establish perceptual equivalence to the reference.

## Acceptance

1. Native Liquid Glass, no colored fill.
2. Core and text remain in place; no uniform whole-button scaling authored by us.
3. Clear difference in response between the four mechanisms.
4. No unexpected double surfaces or seams.
5. Repeatable real holds and clean return to idle.
