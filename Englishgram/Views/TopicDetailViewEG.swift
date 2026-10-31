import SwiftUI

struct TopicDetailViewEG: View {
    @ObservedObject var model: ViewModelEG
    let topic: TopicEG
    @State private var showingLecture = false
    private var progress: TopicProgressEG { model.topicProgress(topic) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    BadgeEG(title: L10nEG.string("Тема \(topic.order)"), color: PaletteEG.red)
                    BadgeEG(title: topic.level)
                    Spacer()
                    Label(L10nEG.string("\(topic.minutes) мин"), systemImage: "clock").font(.subheadline).foregroundStyle(PaletteEG.secondary)
                }
                Text(topic.title).font(.system(.largeTitle, design: .rounded, weight: .black)).foregroundStyle(PaletteEG.navy)
                Text(topic.subtitle).font(.title3).foregroundStyle(PaletteEG.secondary)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Ваш маршрут").font(.headline)
                        Spacer()
                        Text("\(progress.completedStages.count) / 5").font(.subheadline.bold()).foregroundStyle(PaletteEG.navy)
                    }
                    ProgressBarEG(value: Double(progress.completedStages.count) / 5)
                    if progress.completed {
                        Label(L10nEG.string("Лучший результат: \(progress.bestScore)%"), systemImage: "checkmark.seal.fill").font(.subheadline).foregroundStyle(PaletteEG.success)
                    } else { Text("Лекция, три тренировки и финальный тест.").font(.subheadline).foregroundStyle(PaletteEG.secondary) }
                }.cardEG()
                VStack(spacing: 12) {
                    ForEach(StageEG.allCases) { stage in
                        stageRow(stage)
                    }
                }
                Label("Для завершения темы наберите 70% в финальном тесте. Тренировки можно проходить снова.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(PaletteEG.secondary)
            }.padding(20)
        }.screenEG().navigationTitle("Тема").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $showingLecture) { LessonViewEG(model: model, topic: topic) }
    }
    private func stageRow(_ stage: StageEG) -> some View {
        let done = progress.completedStages.contains(stage.rawValue)
        let available = model.canStart(stage, topic: topic)
        return Button {
            if stage == .lecture { showingLecture = true } else { model.start(topic, stage: stage) }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: stage.icon).font(.title2).foregroundStyle(available ? PaletteEG.navy : PaletteEG.secondary)
                    .frame(width: 44, height: 48)
                    .background(PaletteEG.subtle, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(stage.title).font(.headline).foregroundStyle(available ? PaletteEG.ink : PaletteEG.secondary)
                    Text(done ? L10nEG.string("Пройдено · можно повторить") : stage == .lecture ? L10nEG.string("Правила, формулы и примеры") : L10nEG.string("\(topic.questions.filter { $0.stage == stage }.count) вопросов"))
                        .font(.caption).foregroundStyle(PaletteEG.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: done ? "checkmark.circle.fill" : available ? "arrow.right" : "lock.fill")
                    .foregroundStyle(done ? PaletteEG.success : available ? PaletteEG.red : PaletteEG.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }.cardEG()
        }.buttonStyle(PressStyleEG()).disabled(!available)
    }
}

#Preview {
    let model = ViewModelEG(preview: true)
    NavigationStack { if let topic = model.topics.first { TopicDetailViewEG(model: model, topic: topic) } }
}
