import SwiftUI

struct LearnViewEG: View {
    @ObservedObject var model: ViewModelEG
    @State private var confirmingDiscard = false
    private var levels: [String] { model.topics.reduce(into: []) { if !$0.contains($1.level) { $0.append($1.level) } } }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    overview
                    if !model.topics.isEmpty && model.completedTopics.count == model.topics.count {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Весь путь пройден!", systemImage: "checkmark.seal.fill")
                                .font(.title3.bold()).foregroundStyle(PaletteEG.success)
                            Text("Все темы освоены. Возвращайтесь к повторению, чтобы сохранить уверенность.")
                                .font(.subheadline).foregroundStyle(PaletteEG.secondary)
                            PrimaryButtonEG(title: L10nEG.string("К повторению"), icon: "arrow.right") {
                                model.configureReview()
                                model.tab = .review
                            }
                        }.cardEG()
                    }
                    if let draft = model.session {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Тест сохранён", systemImage: "pause.circle.fill").font(.headline)
                            Text("\(draft.title) · \(draft.currentQuestionIndex + 1) / \(draft.questions.count)").font(.subheadline)
                            PrimaryButtonEG(title: L10nEG.string("Продолжить тест"), action: model.resume)
                            Button("Удалить сохранённый тест", role: .destructive) { confirmingDiscard = true }.font(.subheadline).frame(minHeight: 44)
                        }.cardEG()
                    }
                    if let current = model.currentTopic, current.order > 2 {
                        Button { withAnimation { proxy.scrollTo(current.id, anchor: .center) } } label: {
                            Label("К текущей теме", systemImage: "location.fill").font(.subheadline.bold()).frame(minHeight: 44)
                        }
                    }
                    ForEach(levels, id: \.self) { level in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(level).font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(PaletteEG.navy)
                                Text(level == "A1" ? "STARTER" : level == "A2" ? "ELEMENTARY" : "INTERMEDIATE")
                                    .font(.caption.bold()).tracking(2).foregroundStyle(PaletteEG.secondary)
                                Rectangle().fill(PaletteEG.border).frame(height: 1)
                            }.padding(.bottom, 20)
                            ForEach(model.topics.filter { $0.level == level }) { topic in
                                TopicCardEG(topic: topic, progress: model.topicProgress(topic), unlocked: model.isUnlocked(topic),
                                            current: model.currentTopic?.id == topic.id) { model.open(topic) }
                                    .padding(topic.order.isMultiple(of: 2) ? .leading : .trailing, 14).id(topic.id)
                                if topic.id != model.topics.last?.id {
                                    PathConnectorEG(reverse: topic.order.isMultiple(of: 2))
                                        .stroke(PaletteEG.border, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [3, 6]))
                                        .frame(height: 30).padding(.horizontal, 50).accessibilityHidden(true)
                                }
                            }
                        }
                    }
                    Label("В вашем темпе. Полностью офлайн.", systemImage: "leaf")
                        .font(.footnote).foregroundStyle(PaletteEG.secondary).frame(maxWidth: .infinity)
                }.padding(20)
            }.floatingTabContentEG().screenEG().toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Удалить сохранённый тест?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Удалить тест", role: .destructive, action: model.discard)
        } message: { Text("Ответы незавершённой попытки будут удалены. Завершённые этапы сохранятся.") }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 0) {
                    Text("english").foregroundStyle(PaletteEG.navy)
                    Text("gram").foregroundStyle(PaletteEG.red)
                    Circle().fill(PaletteEG.red).frame(width: 5, height: 5).padding(.leading, 3).offset(y: 5)
                }.font(.system(.title3, design: .rounded, weight: .black))
                Spacer()
                Image(systemName: "sparkle").foregroundStyle(PaletteEG.red)
            }.padding(.bottom, 8)
            Text("Продолжаем английский?").font(.subheadline).foregroundStyle(PaletteEG.secondary)
            Text("Путь по грамматике").font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(-1)
        }
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                BadgeEG(title: L10nEG.string("Уровень \(model.currentLevel)"))
                Spacer()
                Label("\(model.progress.xp) XP", systemImage: "star.fill").foregroundStyle(PaletteEG.navy).font(.subheadline.bold())
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(model.completedTopics.count)").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("из \(model.topics.count) тем завершено").font(.subheadline).foregroundStyle(PaletteEG.secondary)
                Spacer(minLength: 0)
            }
            ProgressBarEG(value: Double(model.completedTopics.count) / Double(max(1, model.topics.count)))
            HStack {
                Label("Серия: \(model.stats.streak())", systemImage: "flame.fill").foregroundStyle(PaletteEG.red)
                Spacer()
                Text("Один шаг каждый день").foregroundStyle(PaletteEG.secondary)
            }.font(.caption.weight(.semibold))
        }.cardEG()
    }
}

struct TopicCardEG: View {
    let topic: TopicEG
    let progress: TopicProgressEG
    let unlocked: Bool
    let current: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(current ? PaletteEG.navy : PaletteEG.subtle).frame(width: 52, height: 56)
                    if !unlocked { Image(systemName: "lock.fill").foregroundStyle(PaletteEG.secondary) }
                    else { Text(String(format: "%02d", topic.order)).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(current ? PaletteEG.onAccent : PaletteEG.navy) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    if current { Text("ВАШ СЛЕДУЮЩИЙ ШАГ").font(.caption2.bold()).tracking(1).foregroundStyle(PaletteEG.red) }
                    Text(topic.title).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(unlocked ? PaletteEG.navy : PaletteEG.secondary)
                    Text(topic.subtitle).font(.subheadline).foregroundStyle(PaletteEG.secondary).fixedSize(horizontal: false, vertical: true)
                    if progress.completed {
                        Label(L10nEG.string("Завершено · \(progress.bestScore)%"), systemImage: "checkmark.seal.fill")
                            .font(.caption.bold()).foregroundStyle(PaletteEG.success)
                    } else if unlocked {
                        HStack {
                            Text(progress.completedStages.isEmpty ? L10nEG.string("Начать") : L10nEG.string("Продолжить"))
                            Image(systemName: "arrow.right")
                            Spacer()
                            Text("\(progress.completedStages.count) / 5")
                        }.font(.subheadline.bold()).foregroundStyle(PaletteEG.navy).padding(.top, 5)
                    } else {
                        Text("Завершите предыдущую тему").font(.caption).foregroundStyle(PaletteEG.secondary)
                    }
                }
                Spacer(minLength: 0)
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                .background(PaletteEG.surface, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(current ? PaletteEG.navy.opacity(0.4) : PaletteEG.border, lineWidth: current ? 1.5 : 1))
        }.buttonStyle(PressStyleEG()).disabled(!unlocked)
            .accessibilityHint(unlocked ? Text("Открыть этапы темы") : Text("Тема заблокирована"))
    }
}

struct PathConnectorEG: Shape {
    var reverse: Bool
    func path(in rect: CGRect) -> Path {
        Path { path in
            let start = CGPoint(x: reverse ? rect.maxX * 0.65 : rect.maxX * 0.35, y: 0)
            let end = CGPoint(x: reverse ? rect.maxX * 0.35 : rect.maxX * 0.65, y: rect.maxY)
            path.move(to: start)
            path.addCurve(to: end, control1: CGPoint(x: start.x, y: rect.midY), control2: CGPoint(x: end.x, y: rect.midY))
        }
    }
}

#Preview { NavigationStack { LearnViewEG(model: ViewModelEG(preview: true)) } }
