import SwiftUI

struct MainViewEG: View {
    @ObservedObject var model: ViewModelEG
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack(path: $model.path) {
            Group {
                if model.startupFailed {
                    EmptyStateEG(icon: "externaldrive.badge.exclamationmark", title: L10nEG.string("Данные недоступны"),
                                 detail: L10nEG.string("Перезапустите приложение, чтобы снова открыть локальный курс и прогресс."))
                } else {
                    switch model.tab {
                    case .learn: LearnViewEG(model: model)
                    case .review: ReviewViewEG(model: model)
                    case .study: StudyViewEG(model: model)
                    case .progress: ProgressViewEG(model: model)
                    }
                }
            }
            .navigationDestination(for: TopicEG.self) { TopicDetailViewEG(model: model, topic: $0) }
            .overlay(alignment: .bottom) {
                if model.path.isEmpty && !model.startupFailed { tabBar }
            }
        }
        .tint(PaletteEG.navy).foregroundStyle(PaletteEG.ink)
        .preferredColorScheme(model.settings.appAppearance.colorScheme)
        .environment(\.locale, L10nEG.locale)
        .fullScreenCover(isPresented: $model.showingSession) { TestViewEG(model: model) }
        .alert(L10nEG.string("Englishgram"), isPresented: Binding(get: { model.errorMessage != nil && !model.showingSession }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Понятно", role: .cancel) { model.errorMessage = nil }
            if !model.startupFailed { Button("Повторить сохранение") { model.errorMessage = nil; model.save() } }
        } message: { Text(model.errorMessage ?? "") }
        .sensoryFeedback(trigger: model.feedback) { _, new in
            guard model.settings.haptics else { return nil }
            switch new.kind {
            case .selection: return .selection
            case .success: return .success
            case .error: return .error
            case .completion: return .impact(weight: .heavy, intensity: 0.85)
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.save() } }
    }
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabEG.allCases) { tab in
                Button {
                    model.tab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon).font(.system(size: 20, weight: .semibold))
                        Text(tab.title).font(.caption.weight(.semibold))
                        Capsule().fill(model.tab == tab ? PaletteEG.red : .clear).frame(width: 15, height: 3)
                    }.frame(maxWidth: .infinity).padding(.vertical, 11)
                        .foregroundStyle(model.tab == tab ? PaletteEG.navy : PaletteEG.secondary)
                        .contentShape(Rectangle())
                }.buttonStyle(PressStyleEG())
                    .accessibilityAddTraits(model.tab == tab ? [.isSelected] : [])
            }
        }.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(PaletteEG.border))
            .shadow(color: PaletteEG.navy.opacity(0.1), radius: 14, x: 0, y: 5)
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 6)
    }
}

#Preview { MainViewEG(model: ViewModelEG(preview: true)) }
