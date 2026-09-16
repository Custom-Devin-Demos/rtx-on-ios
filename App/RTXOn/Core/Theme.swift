import RTXOnCore
import SwiftUI

/// NVIDIA-inspired palette: near-black surfaces, one green, white type.
enum Theme {
    static let green = Color(red: 0x76 / 255, green: 0xB9 / 255, blue: 0x00 / 255)
    static let greenBright = Color(red: 0x9A / 255, green: 0xE6 / 255, blue: 0x2A / 255)
    static let background = Color.black
    static let surface = Color(white: 0.07)
    static let surfaceRaised = Color(white: 0.12)
    static let stroke = Color(white: 0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.68)
    static let textTertiary = Color(white: 0.45)
    static let danger = Color(red: 1.0, green: 0.36, blue: 0.32)

    static func color(for beam: BeamColor, muted: Bool = false) -> Color {
        let c: Color
        switch beam {
        case .red: c = Color(red: 1.0, green: 0.30, blue: 0.28)
        case .green: c = green
        case .blue: c = Color(red: 0.30, green: 0.56, blue: 1.0)
        case .yellow: c = Color(red: 1.0, green: 0.86, blue: 0.25)
        case .magenta: c = Color(red: 0.95, green: 0.40, blue: 0.95)
        case .cyan: c = Color(red: 0.30, green: 0.92, blue: 0.95)
        case .white: c = Color(white: 0.96)
        default: c = Color(white: 0.3)
        }
        return muted ? c.opacity(0.55) : c
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

struct CardBackground: ViewModifier {
    var raised = false
    func body(content: Content) -> some View {
        content
            .background(raised ? Theme.surfaceRaised : Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

extension View {
    func card(raised: Bool = false) -> some View { modifier(CardBackground(raised: raised)) }
}

/// Small uppercase label used for section headers, in the NVIDIA style.
struct Eyebrow: View {
    let text: String
    var color = Theme.green
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}
