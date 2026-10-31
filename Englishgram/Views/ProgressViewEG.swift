import SwiftUI

struct ProgressViewEG: View {
    @ObservedObject var model: ViewModelEG
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Ваш прогресс").font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Spacer()
                    NavigationLink { SettingsViewEG(model: model) } label: {
                        Image(systemName: "gearshape.fill").font(.title3).frame(width: 44, height: 44).background(PaletteEG.surface, in: Circle())
                    }.accessibilityLabel("Настройки")
                }
                Text("Маленькие шаги каждый день.").foregroundStyle(PaletteEG.secondary)
                if model.progress.xp == 0 {
                    EmptyStateEG(icon: "chart.bar.xaxis", title: L10nEG.string("Здесь начинается ваш прогресс"),
                                 detail: L10nEG.string("Пройдите первую лекцию и тренировку. Здесь появятся ваши результаты, серия дней и сильные темы."))
                    PrimaryButtonEG(title: L10nEG.string("К первой теме"), icon: "arrow.right") { model.tab = .learn }
                } else {
                    levelCard
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardEG(value: "\(model.completedTopics.count)", title: L10nEG.string("Тем завершено"), icon: "checkmark.seal")
                        StatCardEG(value: "\(model.stats.answers.count)", title: L10nEG.string("Вопросов решено"), icon: "text.bubble")
                        StatCardEG(value: model.stats.answers.isEmpty ? "—" : "\(model.stats.accuracy)%", title: L10nEG.string("Точность"), icon: "scope")
                        StatCardEG(value: "\(model.stats.reviews)", title: L10nEG.string("Повторений"), icon: "arrow.triangle.2.circlepath")
                    }
                    HStack(spacing: 12) {
                        StatCardEG(value: "\(model.learnedWords.count)", title: L10nEG.string("Изучено слов"), icon: "character.book.closed")
                        StatCardEG(value: "\(model.studyReviews)", title: L10nEG.string("Повторений слов"), icon: "rectangle.on.rectangle.angled")
                    }
                    StreakViewEG(days: model.progress.activityDays, streak: model.stats.streak())
                    if !model.rankedTopics(weakest: false).isEmpty {
                        rankings(title: L10nEG.string("Сильные темы"), weak: false)
                        rankings(title: L10nEG.string("Стоит повторить"), weak: true)
                    }
                    if !model.progress.history.isEmpty {
                        SectionHeaderEG(title: L10nEG.string("Последние занятия"))
                        VStack(spacing: 0) {
                            ForEach(model.progress.history.suffix(8).reversed()) { record in
                                NavigationLink { SessionDetailViewEG(record: record) } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: record.isStudy == true ? "character.book.closed" : record.stage?.icon ?? "arrow.triangle.2.circlepath").foregroundStyle(PaletteEG.navy).frame(width: 28)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(record.title).font(.subheadline.bold()).foregroundStyle(PaletteEG.ink)
                                            Text(record.stage?.title ?? L10nEG.string("Повторение")).font(.caption).foregroundStyle(PaletteEG.secondary)
                                            Text(record.endedAt, format: .dateTime.day().month(.abbreviated).hour().minute()).font(.caption2).foregroundStyle(PaletteEG.secondary)
                                        }
                                        Spacer()
                                        Text("\(record.correct)/\(record.answers.count)").font(.headline.monospacedDigit()).foregroundStyle(PaletteEG.navy)
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(PaletteEG.secondary)
                                    }.padding(.vertical, 14)
                                }
                                if record.id != model.progress.history.last?.id { Divider() }
                            }
                        }.cardEG()
                    }
                }
            }.padding(20)
        }.floatingTabContentEG().screenEG().toolbar(.hidden, for: .navigationBar)
    }
    private var levelCard: some View {
        let levelTopics = model.topics.filter { $0.level == model.currentLevel }
        let done = levelTopics.filter { model.topicProgress($0).completed }.count
        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(model.currentLevel).font(.system(.largeTitle, design: .rounded, weight: .black)).foregroundStyle(PaletteEG.navy)
                Spacer()
                Label("\(model.progress.xp) XP", systemImage: "star.fill").font(.headline).foregroundStyle(PaletteEG.navy)
            }
            Text("\(done) из \(levelTopics.count) тем уровня завершено").font(.subheadline).foregroundStyle(PaletteEG.secondary)
            ProgressBarEG(value: Double(done) / Double(max(1, levelTopics.count)))
        }.cardEG()
    }
    private func rankings(title: String, weak: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderEG(title: title)
            ForEach(model.rankedTopics(weakest: weak).prefix(3)) { topic in
                NavigationLink { TopicStatisticsViewEG(model: model, topic: topic) } label: {
                    HStack {
                        Text(topic.title).font(.subheadline.bold())
                        Spacer()
                        Text("\(model.stats.accuracy(for: model.stats.topicAnswers(topic.id)))%").font(.headline.monospacedDigit())
                        Image(systemName: "chevron.right").font(.caption)
                    }.foregroundStyle(PaletteEG.navy).padding(.vertical, 10).frame(minHeight: 44)
                }
            }
        }.cardEG()
    }
}

struct StreakViewEG: View {
    let days: [Date]
    let streak: Int
    private var week: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(L10nEG.string("Дней подряд: \(streak)"), systemImage: "flame.fill").font(.headline).foregroundStyle(PaletteEG.red)
            HStack(spacing: 6) {
                ForEach(week, id: \.self) { day in
                    let active = days.contains { Calendar.current.isDate($0, inSameDayAs: day) }
                    VStack(spacing: 10) {
                        Text(day, format: .dateTime.weekday(.narrow)).font(.caption).foregroundStyle(PaletteEG.secondary)
                        Image(systemName: active ? "checkmark" : "minus").font(.caption.bold())
                            .foregroundStyle(active ? PaletteEG.onAccent : PaletteEG.secondary)
                            .frame(maxWidth: .infinity).frame(height: 32)
                            .background(active ? PaletteEG.navy : PaletteEG.subtle, in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(day, format: .dateTime.day().month()))
                        .accessibilityValue(active ? Text("Занятие завершено") : Text("Без занятий"))
                }
            }
            Text("Завершите этап, изучите слово или повторите материал, чтобы продолжить серию.").font(.caption).foregroundStyle(PaletteEG.secondary)
        }.cardEG()
    }
}

struct TopicStatisticsViewEG: View {
    @ObservedObject var model: ViewModelEG
    let topic: TopicEG
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(topic.title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                HStack(spacing: 12) {
                    StatCardEG(value: "\(model.stats.accuracy(for: model.stats.topicAnswers(topic.id)))%", title: L10nEG.string("Точность"), icon: "scope")
                    StatCardEG(value: "\(model.topicProgress(topic).bestScore)%", title: L10nEG.string("Лучший финал"), icon: "star")
                }
                SectionHeaderEG(title: L10nEG.string("Повторение темы"))
                ReviewSetupViewEG(model: model)
            }.padding(20)
        }.screenEG().navigationTitle("Статистика темы").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .onAppear { model.configureReview(for: topic) }
    }
}

struct SessionDetailViewEG: View {
    let record: SessionRecordEG
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(record.title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(record.endedAt, format: .dateTime.day().month(.wide).year().hour().minute()).foregroundStyle(PaletteEG.secondary)
                HStack(spacing: 12) {
                    StatCardEG(value: "\(record.percentage)%", title: L10nEG.string("Точность"), icon: "scope")
                    StatCardEG(value: "+\(record.xp)", title: L10nEG.string("XP получено"), icon: "star")
                }
                if record.mistakes.isEmpty {
                    Label("Все ответы правильные", systemImage: "checkmark.seal.fill").foregroundStyle(PaletteEG.success)
                } else {
                    NavigationLink { MistakesViewEG(answers: record.mistakes) } label: {
                        Label("Посмотреть ошибки", systemImage: "text.magnifyingglass").font(.headline).frame(minHeight: 50)
                    }
                }
            }.padding(20)
        }.screenEG().navigationTitle("Результат занятия").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}

#Preview { NavigationStack { ProgressViewEG(model: ViewModelEG(preview: true)) } }
#Preview("Статистика темы") {
    let model = ViewModelEG(preview: true)
    NavigationStack { if let topic = model.topics.first { TopicStatisticsViewEG(model: model, topic: topic) } }
}
