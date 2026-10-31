import SwiftUI

@main
struct EnglishgramApp: App {
    @StateObject private var model = ViewModelEG(loadImmediately: false)
    var body: some Scene {
        WindowGroup { AppRootViewEG(model: model) }
    }
}
