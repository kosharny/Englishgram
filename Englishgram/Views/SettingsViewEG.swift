import SwiftUI

struct SettingsViewEG: View {
    @ObservedObject var model: ViewModelEG
    @State private var confirmReset = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section("Обучение") {
                Toggle("Звуки", isOn: setting(\.sounds))
                Toggle("Вибрация", isOn: setting(\.haptics))
                Toggle("Показывать объяснение после ответа", isOn: setting(\.explanations))
            }
            Section("Повторение") {
                Picker("Сложность по умолчанию", selection: setting(\.difficulty)) {
                    ForEach(DifficultyEG.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("Интерфейс") {
                Picker("Оформление", selection: setting(\.appAppearance)) {
                    ForEach(AppearanceEG.allCases) { Text($0.title).tag($0) }
                }
                Picker("Язык", selection: setting(\.appLanguage)) {
                    ForEach(AppLanguageEG.allCases) { Text($0.title).tag($0) }
                }
            }
            Section {
                Button("Сбросить прогресс", role: .destructive) { confirmReset = true }
            } header: { Text("Данные") } footer: { Text("Прогресс и настройки хранятся только на этом устройстве. Подключение к интернету не требуется.") }
            Section("О приложении") {
                LabeledContent("Englishgram", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                Text("Английская грамматика — шаг за шагом. Учитесь, практикуйтесь и замечайте свой прогресс.").font(.subheadline).foregroundStyle(PaletteEG.secondary)
            }
        }.scrollContentBackground(.hidden).background(PaletteEG.background)
            .navigationTitle("Настройки").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .alert("Удалить весь прогресс?", isPresented: $confirmReset) {
                Button("Отмена", role: .cancel) { }
                Button("Сбросить", role: .destructive) { model.reset(); dismiss() }
            } message: { Text("Будут удалены изученные слова, завершённые темы, статистика, серии и результаты тестов. Это действие нельзя отменить.") }
    }
    private func setting<Value>(_ keyPath: WritableKeyPath<SettingsEG, Value>) -> Binding<Value> {
        Binding(get: { model.settings[keyPath: keyPath] }, set: { value in
            var settings = model.settings
            settings[keyPath: keyPath] = value
            model.settings = settings
        })
    }
}

#Preview { NavigationStack { SettingsViewEG(model: ViewModelEG(preview: true)) } }
