import SwiftUI

enum PaletteEG {
    static let background = Color("backgroundEG")
    static let subtle = Color("subtleEG")
    static let navy = Color("navyEG")
    static let red = Color("redEG")
    static let ink = Color("inkEG")
    static let secondary = Color("secondaryEG")
    static let border = Color("borderEG")
    static let success = Color("successEG")
    static let amber = Color("amberEG")
    static let surface = Color("surfaceEG")
    static let onAccent = Color("onAccentEG")
}

struct CardEG: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(PaletteEG.surface, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(PaletteEG.border, lineWidth: 1))
    }
}

extension View {
    func cardEG() -> some View { modifier(CardEG()) }
    func screenEG() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity).background(PaletteEG.background)
    }
}

struct PressStyleEG: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PrimaryButtonEG: View {
    let title: String
    var icon: String? = nil
    var secondary = false
    let action: () -> Void
    @Environment(\.isEnabled) private var enabled
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title).multilineTextAlignment(.center)
                if let icon { Image(systemName: icon) }
            }
            .font(.headline).padding(.horizontal, 18).padding(.vertical, 17)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(secondary ? PaletteEG.navy : PaletteEG.onAccent)
            .background(secondary ? PaletteEG.surface : PaletteEG.navy, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(secondary ? PaletteEG.navy.opacity(0.25) : .clear))
            .opacity(enabled ? 1 : 0.45)
        }.buttonStyle(PressStyleEG())
    }
}

struct ProgressBarEG: View {
    let value: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        GeometryReader { geometry in
            Capsule().fill(PaletteEG.border)
                .overlay(alignment: .leading) {
                    Capsule().fill(PaletteEG.navy)
                        .frame(width: geometry.size.width * min(max(value, 0), 1))
                }
        }.frame(height: 7)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: value)
            .accessibilityLabel(Text("Прогресс"))
            .accessibilityValue(Text("\(Int(value * 100))%"))
    }
}

struct SectionHeaderEG: View {
    let title: String
    var caption: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title3.bold()).foregroundStyle(PaletteEG.ink)
            if let caption { Text(caption).font(.subheadline).foregroundStyle(PaletteEG.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatCardEG: View {
    let value: String
    let title: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundStyle(PaletteEG.navy).font(.title3)
            Text(value).font(.system(.title, design: .rounded, weight: .bold)).foregroundStyle(PaletteEG.ink)
            Text(title).font(.subheadline).foregroundStyle(PaletteEG.secondary)
        }.frame(maxHeight: .infinity, alignment: .topLeading).cardEG()
    }
}

struct BadgeEG: View {
    let title: String
    var color: Color = PaletteEG.navy
    var body: some View {
        Text(title).font(.caption.bold()).foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(color.opacity(0.07), in: Capsule())
    }
}

struct EmptyStateEG: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 48, weight: .medium))
                .foregroundStyle(PaletteEG.navy).padding(28)
                .background(PaletteEG.subtle, in: RoundedRectangle(cornerRadius: 32))
            Text(title).font(.system(.title2, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
            Text(detail).font(.body).foregroundStyle(PaletteEG.secondary).multilineTextAlignment(.center)
        }.padding(.vertical, 36).padding(.horizontal, 12).frame(maxWidth: .infinity)
    }
}

struct FlowLayoutEG: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? 320).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrange(subviews, width: bounds.width)
        for (index, point) in layout.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                                 proposal: ProposedViewSize(width: min(subviews[index].sizeThatFits(.unspecified).width, bounds.width), height: nil))
        }
    }
    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: min(subview.sizeThatFits(.unspecified).width, width), height: nil))
            if x > 0 && x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}

private struct FloatingTabContentEG: ViewModifier {
    @ScaledMetric(relativeTo: .caption) private var clearance = 104
    func body(content: Content) -> some View {
        content
            .contentMargins(.bottom, clearance, for: .scrollContent)
            .ignoresSafeArea(.container, edges: .bottom)
    }
}

extension View {
    func floatingTabContentEG() -> some View { modifier(FloatingTabContentEG()) }
}
