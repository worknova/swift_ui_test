# TDI · Native Liquid Glass Press Lab

Four targeted native SwiftUI hypotheses for a compelling physical press response. This is an optical research experiment, **not** a claim to reproduce any third-party implementation.

## Hypotheses

| Variant | Mechanism | Prediction | Reject if |
| --- | --- | --- | --- |
| **SYSTEM** | One button with `.regular.interactive()`, no authored press animation | Native touch response alone creates a legible, organic lens-like reaction | Only a generic scale/bounce with insufficient rim depth is visible |
| **MORPH** | `GlassEffectContainer` with two persistent side surfaces switching `.identity` / `.regular`; separate fixed native Button and decorative glass layer | Glass surfaces visually coalesce near the **fixed 274×80 pt** core, emphasizing its perimeter | Surfaces stay separate, appear as detached circles, or create visible seams |
| **MEMBRANE** | Non-hit-testing glass layer using custom `@Animatable Shape`; a shared ButtonStyle only observes press state | Ends flex elastically while central glass and typography remain stable | Material fails to track deformation or reads as a mere inflated capsule |
| **OPTICAL_LIP** | A separate native-glass annulus controlled by observed ButtonStyle press state, behind the invariant button label | A visible uninterrupted refracting rim appears on all four sides, while the central glass/text stay fixed | The ring breaks, renders opaque, or appears as a decorative drawn border |

**Controlled conditions:** dark mode; identical 274×80 pt START label; 1.2-second real XCUITest hold; fixed panel and neutral optical grid behind the material. The core must not be uniformly scaled. No colored underlay, tint or artificial glow.

## Measurement

Observe the same stages for each candidate: idle → touch-down → stable hold → release → settled. The optical grid is diagnostic background content, not a button treatment. Compare the peripheral lens, perceived depth, edge continuity, overshoot and return.

A pass in XCTest proves scenario selection and Button activation — **not optical success**. A separate `PRESS begin/end` diagnostic records ButtonStyle.isPressed state transitions to distinguish gesture recognition from button action. A native recording must be inspected before judging the winner.

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
- **CAPTURE** — [`.github/workflows/tdi-glass-capture.yml`](.github/workflows/tdi-glass-capture.yml). Invoke via `workflow_dispatch`, or by updating `.github/tdi-capture.request`. Runs Swift/Python syntax preflight, compiles first, then boots one iPhone simulator and waits for readiness and runs four physical XCTest holds. Uses Xcode's own UI test screen recording retained for successful tests and exported from `.xcresult` with `xcresulttool`. Reports decoded frame timestamps and gap statistics in `capture-quality.json`. The legacy `simctl recordVideo` output is intentionally not used: its previous artifacts had 42-second frame gaps. CI now rejects recordings with >500 ms gaps or timestamps that run backwards; a passing XCTest alone is insufficient. This is a strict quality gate rather than a guarantee of smooth animation.

Run FAST first after source changes; run CAPTURE only after FAST succeeds, when native interaction/optics need evaluation. They intentionally use *separate fresh GitHub runners* so passing FAST does not transfer any compiled cache to CAPTURE. Do not chain them as two sequential jobs in one full capture: this would add cold-runner overhead.

Passing XCTest is not proof of a usable recording. If Xcode's recording still has missing motion during the 1.2-second holds, do not frame-interpolate or label it 60 FPS; use capture from a physical iPhone via QuickTime / device screen recording instead. The video is not a substitute for real-device evaluation. CI's simulator cannot prove 60/120 unique captured frames each second, and XCTest success does not establish perceptual equivalence to the reference.

## Acceptance

1. Native Liquid Glass, no colored fill.
2. Core and text remain in place; no uniform whole-button scaling authored by us.
3. Clear difference in response between the four mechanisms.
4. No unexpected double surfaces or seams.
5. Repeatable real holds and clean return to idle.

## Reliable optical capture: real device

GitHub-hosted iOS Simulator capture is **not suitable for motion-fidelity review** in this experiment. Both `simctl recordVideo` and Xcode's own `.xcresult` video produced dropped frame intervals greater than one second. Continue using GA for build and interaction assertions, not visual animation acceptance.

Run TDILab on a **physical iPhone** and record directly using Control Center > Screen Recording, or connect the iPhone to a Mac with USB and use QuickTime Player > File > New Movie Recording > Camera: iPhone > Record. Transfer the original video unmodified. Inspect decoded frame timestamps and original frames around each 1.2-second hold; do not use synthetic 60 FPS interpolation to mask lost frames. No physical-device capture has yet been tested in this repository.
