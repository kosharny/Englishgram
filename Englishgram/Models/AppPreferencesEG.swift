import SwiftUI

enum AppLanguageEG: String, Codable, CaseIterable, Identifiable {
    case system, ru, pl, uk
    var id: String { rawValue }
    var code: String {
        if self != .system { return rawValue }
        return Locale.preferredLanguages.compactMap { Locale(identifier: $0).language.languageCode?.identifier }
            .first { ["ru", "pl", "uk"].contains($0) } ?? "ru"
    }
    var title: String {
        switch self {
        case .system: L10nEG.string("Как на устройстве")
        case .ru: "Русский"
        case .pl: "Polski"
        case .uk: "Українська"
        }
    }
}

enum AppearanceEG: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    var title: String {
        switch self {
        case .system: L10nEG.string("Как на устройстве")
        case .light: L10nEG.string("Светлое")
        case .dark: L10nEG.string("Тёмное")
        }
    }
}
