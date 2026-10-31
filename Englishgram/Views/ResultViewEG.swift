import SwiftUI

struct ResultViewEG: View {
    @ObservedObject var model: ViewModelEG
    @State private var celebrating = false
    let result: SessionRecordEG
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var passed: Bool { result.stage != .final || result.percentage >= 70 }
    private var stars: Int { result.percentage >= 90 ? 3 : result.percentage >= 75 ? 2 : result.percentage >= 60 ? 1 : 0 }
    private var title: String {
        if result.stage == nil { return L10nEG.string("Повторение завершено") }
        if result.stage == .final { return passed ? L10nEG.string("Тема завершена!") : L10nEG.string("Ещё немного практики") }
        return L10nEG.string("Отличный шаг вперёд!")
    }
    private var groupedSkills: [(String, Int)] {
        Dictionary(grouping: result.answers, by: { result.stage == nil ? topicTitle($0.question.topicID) : $0.question.skill })
            .map { key, value in (key, Int(Double(value.filter(\.correct).count) / Double(value.count) * 100)) }
            .sorted { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 > $1.1 }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    BadgeEG(title: result.stage?.title ?? L10nEG.string("Повторение"))
                    Spacer()
                    Button { model.closeResult() } label: { Image(systemName: "xmark").frame(width: 44, height: 44).background(PaletteEG.subtle, in: Circle()) }
                        .accessibilityLabel("Закрыть результаты")
                }
                VStack(spacing: 16) {
                    Image(systemName: passed ? "checkmark.seal.fill" : "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 66)).foregroundStyle(passed ? PaletteEG.success : PaletteEG.navy)
                        .padding(22).background((passed ? PaletteEG.success : PaletteEG.navy).opacity(0.06), in: Circle())
                        .symbolEffect(.bounce, value: celebrating)
                    Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                    Text(result.title).font(.title3).foregroundStyle(PaletteEG.secondary)
                    HStack(spacing: 10) {
                        ForEach(0..<3) { index in Image(systemName: index < stars ? "star.fill" : "star").foregroundStyle(index < stars ? PaletteEG.amber : PaletteEG.border).font(.title) }
                    }.accessibilityLabel(Text("Звёзд: \(stars) из 3"))
                    Text("\(result.percentage)%").font(.system(size: 64, weight: .black, design: .rounded)).foregroundStyle(PaletteEG.navy)
                    Text("\(result.correct) из \(result.answers.count) правильных ответов").font(.subheadline).foregroundStyle(PaletteEG.secondary)
                }.frame(maxWidth: .infinity)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCardEG(value: "\(result.correct)", title: L10nEG.string("Правильных ответов"), icon: "checkmark.circle")
                    StatCardEG(value: "\(result.mistakes.count)", title: L10nEG.string("Ошибок"), icon: "arrow.uturn.backward")
                    StatCardEG(value: "\(result.bestRun)", title: L10nEG.string("Лучшая серия"), icon: "flame")
                    StatCardEG(value: "+\(result.xp)", title: L10nEG.string("XP получено"), icon: "star")
                }
                if let best = groupedSkills.first {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Сильная сторона", systemImage: "sparkles").font(.headline).foregroundStyle(PaletteEG.navy)
                        Text("\(best.0) · \(best.1)%").font(.body)
                        if let weak = groupedSkills.last, weak.1 < 100 {
                            Divider()
                            Label("Стоит повторить", systemImage: "bookmark").font(.headline).foregroundStyle(PaletteEG.red)
                            Text("\(weak.0) · \(weak.1)%").font(.body)
                        }
                    }.cardEG()
                }
                if result.stage == .final {
                    Label(passed ? L10nEG.string("Тема освоена. Результат сохранён!") : L10nEG.string("Для завершения нужно 70%. Разберите ошибки и попробуйте ещё раз."),
                          systemImage: passed ? "lock.open.fill" : "heart.fill")
                        .font(.subheadline).foregroundStyle(passed ? PaletteEG.success : PaletteEG.secondary)
                }
                VStack(spacing: 12) {
                    if !passed {
                        PrimaryButtonEG(title: L10nEG.string("Повторить тест"), icon: "arrow.clockwise") { model.retry(result) }
                    } else if result.stage == nil {
                        PrimaryButtonEG(title: L10nEG.string("Повторить ещё"), icon: "arrow.clockwise") { model.retry(result) }
                    } else {
                        PrimaryButtonEG(title: result.stage == .final ? L10nEG.string("Завершить тему") : L10nEG.string("Продолжить обучение"), icon: "arrow.right") {
                            model.closeResult()
                        }
                    }
                    if !result.mistakes.isEmpty {
                        NavigationLink { MistakesViewEG(answers: result.mistakes) } label: {
                            Label("Посмотреть ошибки", systemImage: "text.magnifyingglass").font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                        }.buttonStyle(PressStyleEG())
                    }
                    Button("На главную") { model.closeResult(); model.tab = .learn; model.path = [] }.frame(minHeight: 44).font(.subheadline)
                }
            }.padding(20)
        }.screenEG().navigationBarTitleDisplayMode(.inline)
            .onAppear { celebrating = !reduceMotion }
    }
    private func topicTitle(_ id: String) -> String { model.topics.first { $0.id == id }?.title ?? result.title }
}

struct MistakesViewEG: View {
    let answers: [AnswerEG]
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("Ошибки помогают учиться. Обратите внимание на правило в каждом примере.").font(.body).foregroundStyle(PaletteEG.secondary)
                ForEach(answers) { answer in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(answer.question.instruction).font(.caption.bold()).foregroundStyle(PaletteEG.secondary)
                        Text(answer.question.prompt).font(.title3.bold())
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ваш ответ").font(.caption.bold())
                            Label(answer.response, systemImage: "xmark.circle.fill").foregroundStyle(PaletteEG.red)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Правильно").font(.caption.bold())
                            Label(answer.question.answer, systemImage: "checkmark.circle.fill").foregroundStyle(PaletteEG.success)
                        }
                        Divider()
                        Text(answer.question.explanation).font(.body).lineSpacing(4)
                    }.cardEG()
                }
            }.padding(20)
        }.screenEG().navigationTitle("Разбор ошибок").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}

#Preview("Результат") {
    let model = ViewModelEG(preview: true)
    NavigationStack { if let record = model.progress.history.first { ResultViewEG(model: model, result: record) } }
}
#Preview("Ошибки") {
    let model = ViewModelEG(preview: true)
    NavigationStack { MistakesViewEG(answers: model.progress.history.first?.mistakes ?? []) }
}
