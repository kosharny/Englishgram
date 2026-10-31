import SwiftUI

struct LaunchViewEG: View {
    var isLoading = true
    var animatesEntrance = true
    var onIntroFinished: () -> Void = {}
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var markSize = 124

    var body: some View {
        GeometryReader { geometry in
            let symbolSize = min(markSize, geometry.size.height * 0.18)
            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    Circle().fill(PaletteEG.red).frame(width: 6, height: 6)
                    Text("ВАШ АНГЛИЙСКИЙ. ВАШ ТЕМП.")
                        .font(.caption2.bold()).tracking(2).foregroundStyle(PaletteEG.secondary)
                }.padding(.top, 30)
                Spacer(minLength: 24)
                VStack(spacing: 30) {
                    ZStack {
                        Circle().stroke(PaletteEG.border, lineWidth: 1).frame(width: symbolSize * 1.65, height: symbolSize * 1.65)
                        Circle().trim(from: 0, to: revealed ? 0.73 : 0.05)
                            .stroke(PaletteEG.navy.opacity(0.18), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-100)).frame(width: symbolSize * 1.65, height: symbolSize * 1.65)
                        RoundedRectangle(cornerRadius: 32).fill(PaletteEG.navy)
                            .frame(width: symbolSize, height: symbolSize)
                            .rotationEffect(.degrees(revealed ? -5 : -12))
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: symbolSize * 0.46, weight: .regular)).foregroundStyle(PaletteEG.onAccent)
                            .rotationEffect(.degrees(revealed ? -5 : -12))
                        Circle().fill(PaletteEG.red).frame(width: 17, height: 17)
                            .overlay(Circle().stroke(PaletteEG.background, lineWidth: 4))
                            .offset(x: symbolSize * 0.77, y: -symbolSize * 0.28)
                        Image(systemName: "sparkle").font(.title3).foregroundStyle(PaletteEG.red)
                            .offset(x: -symbolSize * 0.72, y: symbolSize * 0.55)
                    }.frame(height: symbolSize * 1.75)
                        .scaleEffect(revealed || reduceMotion || !animatesEntrance ? 1 : 0.9)
                    VStack(spacing: 14) {
                        (Text("english").foregroundStyle(PaletteEG.navy) + Text("gram").foregroundStyle(PaletteEG.red))
                            .font(.system(.largeTitle, design: .rounded, weight: .black)).tracking(-1.5)
                            .accessibilityLabel("Englishgram")
                        Text("Большой английский.\nМаленькими шагами.")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(PaletteEG.secondary).multilineTextAlignment(.center).lineSpacing(5)
                    }
                }.opacity(revealed || reduceMotion || !animatesEntrance ? 1 : 0.5)
                Spacer(minLength: 24)
                VStack(spacing: 24) {
                    if geometry.size.height > 620 && !typeSize.isAccessibilitySize {
                        HStack(spacing: 16) {
                            milestone("ЗНАНИЯ", icon: "book.closed")
                            Capsule().fill(PaletteEG.border).frame(maxWidth: 26).frame(height: 1)
                            milestone("ПРАКТИКА", icon: "pencil.line")
                            Capsule().fill(PaletteEG.border).frame(maxWidth: 26).frame(height: 1)
                            milestone("ПРОГРЕСС", icon: "sparkles")
                        }.accessibilityHidden(true)
                    }
                    HStack(spacing: 10) {
                        if isLoading { ProgressView().controlSize(.small).tint(PaletteEG.navy) }
                        Text(isLoading ? L10nEG.string("Открываем ваш путь…") : L10nEG.string("Всё готово к новому шагу"))
                            .font(.footnote).foregroundStyle(PaletteEG.secondary)
                    }.frame(minHeight: 28)
                }.padding(.bottom, 26)
            }.padding(.horizontal, 28).frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(PaletteEG.background.ignoresSafeArea())
        .onAppear {
            guard !revealed else { return }
            if reduceMotion || !animatesEntrance { revealed = true; onIntroFinished() }
            else {
                withAnimation(.easeInOut(duration: 1.85), completionCriteria: .logicallyComplete) {
                    revealed = true
                } completion: { onIntroFinished() }
            }
        }
    }
    private func milestone(_ title: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon).font(.body).foregroundStyle(PaletteEG.navy)
            Text(title).font(.caption2.bold()).tracking(0.8).foregroundStyle(PaletteEG.secondary)
        }
    }
}

#Preview { LaunchViewEG() }
