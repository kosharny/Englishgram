import SwiftUI

struct AppRootViewEG: View {
    @ObservedObject var model: ViewModelEG
    @State private var introFinished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var showingLaunch: Bool { model.isLoading || !introFinished }

    var body: some View {
        ZStack {
            if showingLaunch {
                LaunchViewEG(isLoading: model.isLoading) { introFinished = true }
                    .transition(.opacity)
            } else {
                MainViewEG(model: model).transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: showingLaunch)
        .preferredColorScheme(model.settings.appAppearance.colorScheme)
        .environment(\.locale, L10nEG.locale)
        .task { await model.loadIfNeeded() }
    }
}

#Preview { AppRootViewEG(model: ViewModelEG(preview: true)) }
