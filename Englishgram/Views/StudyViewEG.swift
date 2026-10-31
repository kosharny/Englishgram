import SwiftUI

struct StudyViewEG: View {
    @ObservedObject var model: ViewModelEG
    @StateObject private var study = StudyViewModelEG()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Изучение").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Новые слова открывают новые возможности.").foregroundStyle(PaletteEG.secondary)
                newWordsCard
                reviewCard
                NavigationLink {
                    LearnedWordsViewEG(model: model)
                } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Все изученные слова", systemImage: "books.vertical.fill").font(.title3.bold())
                        Text("\(model.learnedWords.count)").font(.system(.largeTitle, design: .rounded, weight: .bold))
                        HStack {
                            Text("Открыть словарь").font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.foregroundStyle(PaletteEG.secondary)
                    }.cardEG().foregroundStyle(PaletteEG.navy)
                }.buttonStyle(PressStyleEG())
            }.padding(20)
        }.floatingTabContentEG().screenEG().toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $study.showingCards) {
                StudyFlashcardsViewEG(model: model, study: study)
                    .environment(\.locale, L10nEG.locale)
            }
    }

    private var newWordsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Новые слова", systemImage: "sparkles").font(.title3.bold()).foregroundStyle(PaletteEG.navy)
            if let word = model.newWords.first {
                Text(word.word).font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(word.translation).font(.title3).foregroundStyle(PaletteEG.secondary)
                Text(word.example).font(.subheadline).italic()
                BadgeEG(title: "+10 XP", color: PaletteEG.success)
                PrimaryButtonEG(title: L10nEG.string("Слово изучено"), icon: "checkmark") { model.learnWord(word) }
            } else {
                Text("Все слова изучены! Продолжайте повторять их.").foregroundStyle(PaletteEG.secondary)
            }
        }.cardEG()
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Повторение слов", systemImage: "arrow.triangle.2.circlepath").font(.title3.bold()).foregroundStyle(PaletteEG.navy)
            Text("Закрепляйте слова с карточками и заданиями на перевод.").foregroundStyle(PaletteEG.secondary)
            Picker("Способ повторения", selection: $study.method) {
                ForEach(StudyMethodEG.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.menu)
            PrimaryButtonEG(title: L10nEG.string("Начать повторение"), icon: "play.fill") {
                if study.method == .flashcards { study.startCards(words: model.learnedWords) }
                else { model.startVocabularyReview(reverse: study.method == .reverse) }
            }.disabled(study.method == .flashcards ? model.learnedWords.isEmpty : model.learnedWords.count < 2)
            if model.learnedWords.count < 2 {
                Text("Изучите одно слово для карточек и два — для заданий на перевод.").font(.caption).foregroundStyle(PaletteEG.secondary)
            }
        }.cardEG()
    }
}

struct LearnedWordsViewEG: View {
    @ObservedObject var model: ViewModelEG
    @StateObject private var study = StudyViewModelEG()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if model.learnedWords.isEmpty {
                    EmptyStateEG(icon: "books.vertical", title: L10nEG.string("Ваш словарь пока пуст"),
                                 detail: L10nEG.string("Изучите первое слово на экране «Изучение»."))
                } else if study.filteredWords(model.learnedWords).isEmpty {
                    ContentUnavailableView.search(text: study.search)
                } else {
                    ForEach(study.filteredWords(model.learnedWords)) { word in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(word.word).font(.title3.bold()).foregroundStyle(PaletteEG.navy)
                            Text(word.translation).font(.body)
                            Text(word.example).font(.subheadline).foregroundStyle(PaletteEG.secondary)
                        }.cardEG()
                    }
                }
            }.padding(20)
        }.searchable(text: $study.search, prompt: "Найти слово")
            .screenEG().navigationTitle("Все изученные слова")
            .navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}

struct StudyFlashcardsViewEG: View {
    @ObservedObject var model: ViewModelEG
    @ObservedObject var study: StudyViewModelEG
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if study.completed {
                        EmptyStateEG(icon: "checkmark.seal.fill", title: L10nEG.string("Повторение завершено"),
                                     detail: L10nEG.string("Ваш прогресс сохранён. Возвращайтесь завтра!"))
                        PrimaryButtonEG(title: L10nEG.string("Дальше")) { dismiss() }
                    } else if let word = study.currentWord {
                        ProgressBarEG(value: Double(study.index) / Double(max(1, study.cards.count)))
                        VStack(spacing: 24) {
                            Text(word.word).font(.system(.largeTitle, design: .rounded, weight: .bold))
                            if study.revealed {
                                Text(word.translation).font(.title2).foregroundStyle(PaletteEG.navy)
                                Text(word.example).font(.body).foregroundStyle(PaletteEG.secondary)
                            }
                        }.frame(minHeight: 240).frame(maxWidth: .infinity).cardEG()
                        if study.revealed {
                            PrimaryButtonEG(title: L10nEG.string("Помню"), icon: "checkmark") { study.advance(remembered: true, model: model) }
                            PrimaryButtonEG(title: L10nEG.string("Повторить позже"), secondary: true) { study.advance(remembered: false, model: model) }
                        } else {
                            PrimaryButtonEG(title: L10nEG.string("Показать перевод")) { study.reveal() }
                        }
                    }
                }.padding(20)
            }.screenEG().navigationTitle("Карточки").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } } }
        }.tint(PaletteEG.navy).preferredColorScheme(model.settings.appAppearance.colorScheme)
    }
}

#Preview { NavigationStack { StudyViewEG(model: ViewModelEG(preview: true)) } }
