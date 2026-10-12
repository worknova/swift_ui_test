import SwiftUI

// TDI optical comparison: four mechanisms, one fixed geometry, one real touch.
// Minimum deployment: iOS 26. The ONLY rendered material is native Liquid Glass.
// No colored tint, painted halo, gradients, or full-button scaleEffect.

@main
struct TDILabApp: App {
    var body: some Scene {
        WindowGroup { TDIExperimentScreen() }
    }
}

private enum TDIMode: Int, CaseIterable {
    case system, morph, membrane, opticalLip

    var code: String {
        switch self {
        case .system: "SYSTEM"
        case .morph: "MORPH"
        case .membrane: "MEMBRANE"
        case .opticalLip: "OPTICAL_LIP"
        }
    }

    var title: String {
        switch self {
        case .system: "System glass response"
        case .morph: "Glass surface morphing"
        case .membrane: "Local edge deformation"
        case .opticalLip: "Continuous optical rim"
        }
    }

    var question: String {
        switch self {
        case .system: "Can native interactive glass create the lens on its own?"
        case .morph: "Will peripheral glass volumes merge into the fixed core?"
        case .membrane: "Can only the ends deform, without core scaling?"
        case .opticalLip: "Can a real glass annulus grow around a fixed core?"
        }
    }

    var signature: String { "\(rawValue + 1)/\(TDIMode.allCases.count)|\(code)|NEUTRAL|HOLD-1.2" }
    var buttonIdentifier: String { "tdi\(code)Button" }
}

// Fixed monochrome optical reference for observing the glass refraction.
// This is content BEHIND glass, not a fill or tint applied to the button.
private struct TDIOpticalReference: View {
    var body: some View {
        Canvas { context, size in
            var lines = Path()
            let step: CGFloat = 20
            for x in stride(from: step, through: size.width, by: step) {
                lines.move(to: CGPoint(x: x, y: 0))
                lines.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: step, through: size.height, by: step) {
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(lines, with: .color(.white.opacity(0.105)), lineWidth: 0.7)

            // Four fixed measurement marks. No dynamic colored underlight.
            for dx in [-95.0, -32.0, 32.0, 95.0] {
                let circle = Path(ellipseIn: CGRect(
                    x: size.width / 2 + dx - 1.4,
                    y: size.height / 2 - 1.4,
                    width: 2.8, height: 2.8
                ))
                context.fill(circle, with: .color(.white.opacity(0.48)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct TDIExperimentScreen: View {
    @State private var mode: TDIMode = .system
    @State private var releases: Int = 0
    private let backdrop = Color(red: 0.035, green: 0.045, blue: 0.065)
    private let panel = Color(red: 0.07, green: 0.12, blue: 0.18)

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("TDI · LIQUID GLASS PRESS LAB")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.66))

                Text(mode.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)

                Text(mode.question)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(height: 38)

                RoundedRectangle(cornerRadius: 18)
                    .fill(panel)
                    .overlay {
                        TDIOpticalReference()
                            .clipShape(.rect(cornerRadius: 18))
                    }
                    .frame(maxWidth: 390)
                    .frame(height: 242)
                    .overlay { experimentalButton }

                Text(mode.signature)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.77))
                    .accessibilityIdentifier("tdiVariantSignature")

                Text("RELEASES \(releases)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.69))
                    .accessibilityIdentifier("tdiReleaseCounter")

                Button("Next hypothesis") {
                    guard let next = TDIMode(rawValue: mode.rawValue + 1) else { return }
                    mode = next
                    releases = 0
                }
                .buttonStyle(.bordered)
                .disabled(mode == .opticalLip)
                .accessibilityIdentifier("tdiNextHypothesis")

                Text("Same 274 × 80 pt core · hold 1.2 seconds")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(18)
        }
        .preferredColorScheme(.dark)
    }

    private var startLabel: some View {
        Text("START")
            .font(.system(size: 26, weight: .bold))
            .tracking(2.3)
            .foregroundStyle(.white)
            .frame(width: 274, height: 80)
            .contentShape(Capsule())
    }

    private func onRelease() { releases += 1 }

    @ViewBuilder
    private var experimentalButton: some View {
        switch mode {
        case .system:
            Button(action: onRelease) { startLabel }
                .buttonStyle(.plain)
                // H1: native response, zero custom geometry or press animation.
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")

        case .morph:
            Button(action: onRelease) { startLabel }
                .buttonStyle(TDIMorphStyle())
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")

        case .membrane:
            Button(action: onRelease) { startLabel }
                .buttonStyle(TDIMembraneStyle())
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")

        case .opticalLip:
            Button(action: onRelease) { startLabel }
                .buttonStyle(TDIOpticalLipStyle())
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")
        }
    }
}

// H2 — Native glass geometry transition, NOT a capsule scaled up.
// The 274x80 core never changes. During touch-down, two native glass
// satellite surfaces become visible next to its ends, where the shared
// GlassEffectContainer may blend their geometry with the core.
// Matched-geometry changes are restricted to GLASS (text remains still).
private struct TDIMorphStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TDIMorphBody(configuration: configuration)
    }

    private struct TDIMorphBody: View {
        let configuration: ButtonStyle.Configuration
        @Namespace private var glassNamespace
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            GlassEffectContainer(spacing: 22) {
                ZStack {
                    // The real, hit-testable Button label owns interactive glass.
                    configuration.label
                        .frame(width: 274, height: 80)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .glassEffectID("core", in: glassNamespace)

                    // Keep both satellite views mounted for the entire gesture.
                    // A press must never insert/remove hit-test relevant views:
                    // previous conditional insertion cancelled the Button action.
                    Color.clear
                        .frame(width: 66, height: 66)
                        .glassEffect(
                            configuration.isPressed && !reduceMotion ? .regular : .identity,
                            in: .circle
                        )
                        .glassEffectID("west", in: glassNamespace)
                        .glassEffectTransition(.matchedGeometry)
                        .offset(x: -126)
                        .allowsHitTesting(false)

                    Color.clear
                        .frame(width: 66, height: 66)
                        .glassEffect(
                            configuration.isPressed && !reduceMotion ? .regular : .identity,
                            in: .circle
                        )
                        .glassEffectID("east", in: glassNamespace)
                        .glassEffectTransition(.matchedGeometry)
                        .offset(x: 126)
                        .allowsHitTesting(false)
                }
                .frame(width: 322, height: 126)
            }
            .contentShape(Rectangle())
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.78),
                value: configuration.isPressed
            )
        }
    }
}

// H3 — One interactive glass surface with a custom animatable Shape.
// No overlaid glass, fake border, or scaled center. Only the lateral
// contours deform; the top/bottom center and START stay stationary.
@Animatable
private struct TDIElasticOutline: Shape {
    var deformation: CGFloat

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let left = cx - 137
        let right = cx + 137
        let top = cy - 40
        let bottom = cy + 40
        let d = max(0, min(1, deformation)) * 14

        var path = Path()
        path.move(to: CGPoint(x: left + 40, y: top))
        path.addLine(to: CGPoint(x: right - 40, y: top))
        path.addCurve(
            to: CGPoint(x: right + d, y: cy),
            control1: CGPoint(x: right - 14, y: top),
            control2: CGPoint(x: right + d, y: top + 15)
        )
        path.addCurve(
            to: CGPoint(x: right - 40, y: bottom),
            control1: CGPoint(x: right + d, y: bottom - 15),
            control2: CGPoint(x: right - 14, y: bottom)
        )
        path.addLine(to: CGPoint(x: left + 40, y: bottom))
        path.addCurve(
            to: CGPoint(x: left - d, y: cy),
            control1: CGPoint(x: left + 14, y: bottom),
            control2: CGPoint(x: left - d, y: bottom - 15)
        )
        path.addCurve(
            to: CGPoint(x: left + 40, y: top),
            control1: CGPoint(x: left - d, y: top + 15),
            control2: CGPoint(x: left + 14, y: top)
        )
        path.closeSubpath()
        return path
    }
}

private struct TDIMembraneStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 322, height: 126)
            // Glass attached to the actual interactive button label,
            // not a Color.clear sibling with disabled hit-testing.
            .glassEffect(
                .regular.interactive(),
                in: TDIElasticOutline(
                    deformation: (!reduceMotion && configuration.isPressed) ? 1 : 0
                )
            )
            .contentShape(Rectangle())
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.69),
                value: configuration.isPressed
            )
    }
}

// H4 — PERIPHERAL LENS / OPTICAL LIP.
// A continuous, real GLASS annulus encircles a dimensionally fixed core.
// During touch-down the outside edge grows in all directions, while the
// inside edge, glass core and typography remain stationary.
//
// The annular Shape uses *opposite winding* for inner/outer subpaths,
// i.e. it describes a real hole without post-material .mask / .opacity
// tricks that can flatten the glass lens. Whether the native material
// honors the expected inner refraction must be verified on the iPhone.
@Animatable
private struct TDIContinuousGlassLip: Shape {
    var emergence: CGFloat

    func path(in rect: CGRect) -> Path {
        let t = max(0, min(1, emergence))
        let base = CGRect(x: rect.midX - 137, y: rect.midY - 40,
                          width: 274, height: 80)
        // Inner lip overlaps the unchanged core by 2 points, to prevent
        // a transparent gap during the system compositing transition.
        let inner = base.insetBy(dx: 2, dy: 2)
        // This is a separate peripheral GLASS surface, not the core scaled.
        let outer = base.insetBy(dx: -18 * t, dy: -18 * t)
        var lens = Path()
        lens.addRoundedRect(
            in: outer,
            cornerSize: CGSize(width: outer.height / 2, height: outer.height / 2)
        )
        var aperture = Path()
        aperture.addRoundedRect(
            in: inner,
            cornerSize: CGSize(width: inner.height / 2, height: inner.height / 2)
        )
        // Reflecting horizontally flips winding. A nonzero-fill renderer
        // therefore treats the inner capsule as a hole.
        let invertWinding = CGAffineTransform(
            translationX: rect.midX * 2, y: 0
        ).scaledBy(x: -1, y: 1)
        lens.addPath(aperture, transform: invertWinding)
        return lens
    }
}

private struct TDIOpticalLipStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Render system material only in the external rim. This
            // layer is visual; it never competes for physical touches.
            Color.clear
                .frame(width: 330, height: 130)
                .glassEffect(
                    .regular,
                    in: TDIContinuousGlassLip(
                        emergence: (!reduceMotion && configuration.isPressed) ? 1 : 0
                    )
                )
                .opacity(configuration.isPressed && !reduceMotion ? 1 : 0)
                .allowsHitTesting(false)

            configuration.label
                .frame(width: 274, height: 80)
                .glassEffect(.regular.interactive(), in: .capsule)
        }
        .frame(width: 330, height: 130)
        .contentShape(Rectangle())
        .animation(
            reduceMotion ? nil : .spring(response: 0.19, dampingFraction: 0.77),
            value: configuration.isPressed
        )
    }
}
