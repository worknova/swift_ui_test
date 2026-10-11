import SwiftUI

// A single optically neutral test scene for three independent hypotheses.
// No colored backing, no tint and no system-press substitute animation.
@main
struct TDILabApp: App {
    var body: some Scene {
        WindowGroup { TDIExperimentScreen() }
    }
}

private enum TDIMode: Int, CaseIterable {
    case system, lens, membrane

    var code: String {
        switch self {
        case .system: "SYSTEM"
        case .lens: "LENS"
        case .membrane: "MEMBRANE"
        }
    }

    var title: String {
        switch self {
        case .system: "Native interactive glass"
        case .lens: "Peripheral glass lens"
        case .membrane: "Elastic glass membrane"
        }
    }

    var question: String {
        switch self {
        case .system: "Does the native interaction create sufficient optical depth?"
        case .lens: "Does a separate glass perimeter read as a raised lens?"
        case .membrane: "Can the ends flex without enlarging the button core?"
        }
    }

    var signature: String { "\(rawValue + 1)/3|\(code)|NEUTRAL|HOLD-1.2" }
    var buttonIdentifier: String { "tdi\(code)Button" }
}

struct TDIExperimentScreen: View {
    @State private var mode: TDIMode = .system
    @State private var releases = 0

    private let backdrop = Color(red: 0.035, green: 0.045, blue: 0.065)
    private let panel = Color(red: 0.07, green: 0.12, blue: 0.18)

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("TDI · NATIVE GLASS LAB")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.3)
                    .foregroundStyle(.white.opacity(0.64))

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
                .disabled(mode == .membrane)
                .accessibilityIdentifier("tdiNextHypothesis")

                Text("One 274 × 80 pt core · one 1.2 s long press")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.46))
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

    private func recordRelease() { releases += 1 }

    @ViewBuilder
    private var experimentalButton: some View {
        switch mode {
        case .system:
            Button(action: recordRelease) { startLabel }
                .buttonStyle(.plain)
                // H1: the native interaction system is the entire mechanism.
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")

        case .lens:
            Button(action: recordRelease) { startLabel }
                .buttonStyle(TDIPeripheralLensStyle())
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")

        case .membrane:
            Button(action: recordRelease) { startLabel }
                .buttonStyle(TDIElasticEdgeStyle())
                .accessibilityLabel("START")
                .accessibilityIdentifier(mode.buttonIdentifier)
                .accessibilityValue("\(mode.code)|NEUTRAL|GLASS")
        }
    }
}

// H2: the glass core never changes size or color. An annular glass
// perimeter appears at touch-down. It is a second *system glass surface*,
// not an opaque border, a glow, or a colored backing.
private struct TDIPeripheralLensStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlassEffectContainer(spacing: 0) {
            ZStack {
                Color.clear
                    .frame(width: 274, height: 80)
                    .glassEffect(.regular, in: .capsule)
                    .allowsHitTesting(false)

                Color.clear
                    .frame(width: 304, height: 108)
                    .glassEffect(.regular, in: .capsule)
                    .mask {
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: 10)
                            .frame(width: 304, height: 108)
                    }
                    .opacity(configuration.isPressed ? 1 : 0)
                    .allowsHitTesting(false)

                configuration.label
                    .frame(width: 274, height: 80)
            }
            .frame(width: 322, height: 126)
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.22, dampingFraction: 0.78),
                   value: configuration.isPressed)
    }
}

// H3: the glass geometry changes only near the ends. The central
// 274x80 region and the START label keep their location and size.
private struct TDIElasticOutline: Shape {
    var deformation: CGFloat

    var animatableData: CGFloat {
        get { deformation }
        set { deformation = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let l = cx - 137, r = cx + 137
        let t = cy - 40, b = cy + 40
        let d = max(0, min(1, deformation)) * 14
        var path = Path()
        path.move(to: CGPoint(x: l + 40, y: t))
        path.addLine(to: CGPoint(x: r - 40, y: t))
        path.addCurve(to: CGPoint(x: r + d, y: cy),
                      control1: CGPoint(x: r - 14, y: t),
                      control2: CGPoint(x: r + d, y: t + 15))
        path.addCurve(to: CGPoint(x: r - 40, y: b),
                      control1: CGPoint(x: r + d, y: b - 15),
                      control2: CGPoint(x: r - 14, y: b))
        path.addLine(to: CGPoint(x: l + 40, y: b))
        path.addCurve(to: CGPoint(x: l - d, y: cy),
                      control1: CGPoint(x: l + 14, y: b),
                      control2: CGPoint(x: l - d, y: b - 15))
        path.addCurve(to: CGPoint(x: l + 40, y: t),
                      control1: CGPoint(x: l - d, y: t + 15),
                      control2: CGPoint(x: l + 14, y: t))
        path.closeSubpath()
        return path
    }
}

private struct TDIElasticEdgeStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Color.clear
                .frame(width: 322, height: 126)
                .glassEffect(.regular, in: TDIElasticOutline(
                    deformation: configuration.isPressed ? 1 : 0
                ))
                .allowsHitTesting(false)

            configuration.label
                .frame(width: 274, height: 80)
        }
        .frame(width: 322, height: 126)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.24, dampingFraction: 0.69),
                   value: configuration.isPressed)
    }
}
