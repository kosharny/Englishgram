import SwiftUI

struct ReviewViewEG: View {
    @ObservedObject var model: ViewModelEG
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Повторение").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Закрепите то, что уже изучили").font(.body).foregroundStyle(PaletteEG.secondary)
                if model.completedTopics.isEmpty {
                    EmptyStateEG(icon: "arrow.triangle.2.circlepath", title: L10nEG.string("Сначала изучите первую тему"),
                        detail: L10nEG.string("После завершения темы здесь появятся задания для повторения."))
                    PrimaryButtonEG(title: L10nEG.string("Начать обучение"), icon: "arrow.right") { model.tab = .learn }
                } else {
                    HStack(spacing: 12) {
                        StatCardEG(value: "\(model.completedTopics.count)", title: L10nEG.string("Изучено тем"), icon: "book.closed")
                        StatCardEG(value: "\(model.stats.answers.count)", title: L10nEG.string("Вопросов решено"), icon: "checkmark.bubble")
                    }
                    ReviewSetupViewEG(model: model)
                }
            }.padding(20)
        }.floatingTabContentEG().screenEG().toolbar(.hidden, for: .navigationBar)
            .onAppear { if model.selectedTopics.isEmpty { model.configureReview() } }
    }
}

struct ReviewSetupViewEG: View {
    @ObservedObject var model: ViewModelEG
    private var availableCount: Int {
        min(model.reviewCount, model.completedTopics.filter { model.selectedTopics.contains($0.id) }.flatMap(\.questions).count)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeaderEG(title: L10nEG.string("Темы"))
                    Button("Все изученные") { model.selectedTopics = Set(model.completedTopics.map(\.id)) }.font(.caption.bold()).frame(minHeight: 44)
                }
                FlowLayoutEG {
                    ForEach(model.completedTopics) { topic in
                        let selected = model.selectedTopics.contains(topic.id)
                        Button {
                            if selected { model.selectedTopics.remove(topic.id) } else { model.selectedTopics.insert(topic.id) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                Text(topic.title)
                            }.font(.subheadline.weight(.semibold)).padding(12).frame(minHeight: 44)
                                .foregroundStyle(selected ? PaletteEG.navy : PaletteEG.secondary)
                                .background(selected ? PaletteEG.navy.opacity(0.06) : PaletteEG.surface, in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? PaletteEG.navy.opacity(0.4) : PaletteEG.border))
                        }.buttonStyle(PressStyleEG()).accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderEG(title: L10nEG.string("Вопросов в сессии"))
                Picker("Количество вопросов", selection: $model.reviewCount) {
                    ForEach([5, 10, 15, 20], id: \.self) { Text("\($0)").tag($0) }
                }.pickerStyle(.segmented)
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderEG(title: L10nEG.string("Сложность"))
                Picker("Сложность", selection: $model.reviewDifficulty) {
                    ForEach(DifficultyEG.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
                Text(model.reviewDifficulty.detail).font(.subheadline).foregroundStyle(PaletteEG.secondary)
            }
            HStack {
                SectionHeaderEG(title: L10nEG.string("Тип заданий"))
                Picker("Тип заданий", selection: $model.reviewType) {
                    ForEach(ReviewTypeEG.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.menu)
            }
            Label("Задания, в которых вы ошибались, будут встречаться немного чаще.", systemImage: "sparkles")
                .font(.footnote).foregroundStyle(PaletteEG.secondary)
            PrimaryButtonEG(title: L10nEG.string("Начать повторение"), icon: "arrow.right", action: model.startReview)
                .disabled(model.selectedTopics.isEmpty)
            Text("Вопросов: \(availableCount) · Тем: \(model.selectedTopics.count) · \(model.reviewDifficulty.title)")
                .font(.caption).foregroundStyle(PaletteEG.secondary).frame(maxWidth: .infinity)
            if model.reviewType != .mixed {
                Text("Если заданий выбранного типа не хватит, добавим другие из тех же тем.").font(.caption).foregroundStyle(PaletteEG.secondary)
            }
        }
    }
}

#Preview { NavigationStack { ReviewViewEG(model: ViewModelEG(preview: true)) } }
