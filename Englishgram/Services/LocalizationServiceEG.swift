import Foundation

@MainActor
enum L10nEG {
    static var language: AppLanguageEG = .system
    static var locale: Locale { Locale(identifier: language.code) }
    static var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: language.code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
    static func string(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: bundle, locale: locale)
    }

    private static let translations: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "CourseTranslationsEG", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return values
    }()
    private static let sources: [String: String] = {
        var values: [String: String] = [:]
        for dictionary in translations.values {
            for (source, translated) in dictionary where values[translated] == nil { values[translated] = source }
        }
        return values
    }()
    static func text(_ value: String) -> String {
        let source = translations["pl"]?[value] != nil ? value : sources[value] ?? value
        return translations[language.code]?[source] ?? source
    }
    static func localizeJSON(_ data: Data) throws -> Data {
        func translate(_ value: Any) -> Any {
            if let string = value as? String { return text(string) }
            if let array = value as? [Any] { return array.map(translate) }
            if let dictionary = value as? [String: Any] { return dictionary.mapValues(translate) }
            return value
        }
        return try JSONSerialization.data(withJSONObject: translate(JSONSerialization.jsonObject(with: data)))
    }
}
