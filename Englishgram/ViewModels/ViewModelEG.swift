import SwiftUI
import Combine

@MainActor
final class ViewModelEG: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var topics: [TopicEG] = []
    @Published var progress = UserProgressEG()
    @Published var tab: TabEG = .learn
    @Published var path: [TopicEG] = []
    @Published var showingSession = false
    @Published var result: SessionRecordEG?
    @Published var errorMessage: String?
    @Published var startupFailed = false
    @Published var selectedTopics: Set<String> = []
    @Published var reviewCount = 10
    @Published var reviewDifficulty: DifficultyEG = .normal
    @Published var reviewType: ReviewTypeEG = .mixed
    @Published var feedback: FeedbackEG = .init()
    private var persistence: ProgressServiceEG?
    private let sound = SoundServiceEG()

    init(preview: Bool = false, loadImmediately: Bool = true) {
        if loadImmediately { load(preview: preview) }
        else { isLoading = true }
    }

    func loadIfNeeded() async {
        guard isLoading else { return }
        await Task.yield()
        guard !Task.isCancelled, isLoading else { return }
        load(preview: false)
    }

    private func load(preview: Bool) {
        defer { isLoading = false }
        do {
            persistence = try ProgressServiceEG(inMemory: preview)
            if let persistence { progress = try persistence.load() }
            L10nEG.language = settings.appLanguage
            progress = try localizedProgress(progress)
            topics = try CourseServiceEG.load()
            reviewDifficulty = progress.settings.difficulty
            if preview { populatePreview() }
        } catch {
            startupFailed = true
            errorMessage = L10nEG.string("Не удалось открыть локальные данные. Перезапустите приложение. Ваш прогресс не будет перезаписан.")
        }
    }

    init(topics: [TopicEG], persistence: ProgressServiceEG) throws {
        self.topics = topics
        self.persistence = persistence
        progress = try persistence.load()
        L10nEG.language = settings.appLanguage
        progress = try localizedProgress(progress)
        self.topics = try JSONDecoder().decode([TopicEG].self, from: L10nEG.localizeJSON(JSONEncoder().encode(topics)))
        reviewDifficulty = progress.settings.difficulty
    }

    private func localizedProgress(_ value: UserProgressEG) throws -> UserProgressEG {
        try JSONDecoder().decode(UserProgressEG.self, from: L10nEG.localizeJSON(JSONEncoder().encode(value)))
    }

    var stats: StatisticsEG { StatisticsEG(progress: progress) }
    var completedTopics: [TopicEG] { topics.filter { topicProgress($0).completed } }
    var currentTopic: TopicEG? { topics.first { !topicProgress($0).completed } }
    var session: TestSessionEG? { progress.draft }
    var currentLevel: String { currentTopic?.level ?? topics.last?.level ?? "A1" }
    var settings: SettingsEG {
        get { progress.settings }
        set {
            let previousSettings = settings
            if previousSettings.appLanguage != newValue.appLanguage {
                L10nEG.language = newValue.appLanguage
                do {
                    let localizedTopics = try JSONDecoder().decode([TopicEG].self,
                        from: L10nEG.localizeJSON(JSONEncoder().encode(topics)))
                    var candidate = progress
                    candidate.settings = newValue
                    let localized = try localizedProgress(candidate)
                    topics = localizedTopics
                    progress = localized
                    path = path.compactMap { old in topics.first { $0.id == old.id } }
                    if let result { self.result = progress.history.first { $0.id == result.id } }
                } catch {
                    L10nEG.language = previousSettings.appLanguage
                    errorMessage = L10nEG.string("Не удалось изменить язык. Попробуйте снова.")
                    return
                }
            } else {
                progress.settings = newValue
            }
            if previousSettings.difficulty != newValue.difficulty { reviewDifficulty = newValue.difficulty }
            save()
        }
    }
    func topicProgress(_ topic: TopicEG) -> TopicProgressEG { progress.topics[topic.id] ?? TopicProgressEG() }
    func isUnlocked(_ topic: TopicEG) -> Bool {
        guard let index = topics.firstIndex(where: { $0.id == topic.id }) else { return false }
        return index == 0 || topicProgress(topics[index - 1]).completed
    }
    func canStart(_ stage: StageEG, topic: TopicEG) -> Bool {
        isUnlocked(topic) && (stage == .lecture || topicProgress(topic).completedStages.contains(stage.rawValue - 1))
    }
    func open(_ topic: TopicEG) {
        guard isUnlocked(topic) else { return }
        path.append(topic)
    }
    func completeLecture(_ topic: TopicEG) {
        guard isUnlocked(topic) else { return }
        if !topicProgress(topic).completedStages.contains(0) {
            progress.topics[topic.id, default: TopicProgressEG()].completedStages.insert(0)
            progress.lectureXP += StageEG.lecture.xp
            markActivity()
            signal(.success)
            save()
        }
    }
    func start(_ topic: TopicEG, stage: StageEG) {
        guard stage != .lecture, canStart(stage, topic: topic) else { return }
        if let draft = session, draft.topicID == topic.id, draft.stage == stage { resume(); return }
        guard session == nil else {
            errorMessage = L10nEG.string("Сначала завершите или удалите сохранённый тест в разделе «Учиться».")
            return
        }
        var new = TestSessionEG(title: topic.title, topicID: topic.id, stage: stage,
                                questions: topic.questions.filter { $0.stage == stage }.shuffled())
        guard !new.questions.isEmpty else { return }
        new.prepareQuestion()
        progress.draft = new
        result = nil
        save()
        showingSession = true
    }
    func resume() { result = nil; showingSession = session != nil }
    func pause() { save(); showingSession = false }
    func discard() { progress.draft = nil; save() }
    func select(_ answer: String) {
        guard session?.checked == false else { return }
        progress.draft?.selectedAnswer = answer
        signal(.selection)
        save()
    }
    func toggleToken(_ index: Int) {
        guard let draft = session, !draft.checked, draft.tokenOrder.indices.contains(index) else { return }
        if let selectedIndex = draft.constructedSentence.firstIndex(of: index) {
            progress.draft?.constructedSentence.remove(at: selectedIndex)
        } else { progress.draft?.constructedSentence.append(index) }
        signal(.selection)
        save()
    }
    func check() {
        guard session?.canCheck == true else { return }
        progress.draft?.check()
        signal(session?.answers.last?.correct == true ? .success : .error)
        save()
    }
    func next() {
        guard var draft = session, draft.checked else { return }
        if draft.isLast { finish(draft); return }
        draft.currentQuestionIndex += 1
        draft.prepareQuestion()
        progress.draft = draft
        save()
    }
    private func finish(_ draft: TestSessionEG) {
        guard !progress.history.contains(where: { $0.id == draft.id }) else { return }
        let correct = draft.answers.filter(\.correct).count
        let passed = Double(correct) / Double(draft.questions.count) >= 0.7
        var xp = correct * 5
        if let id = draft.topicID, let stage = draft.stage {
            let alreadyDone = progress.topics[id]?.completedStages.contains(stage.rawValue) == true
            if stage != .final || passed {
                progress.topics[id, default: TopicProgressEG()].completedStages.insert(stage.rawValue)
                if !alreadyDone { xp += stage.xp }
            }
            if stage == .final {
                let score = Int((Double(correct) / Double(draft.questions.count) * 100).rounded())
                progress.topics[id, default: TopicProgressEG()].bestScore = max(progress.topics[id]?.bestScore ?? 0, score)
            }
        }
        let record = SessionRecordEG(id: draft.id, title: draft.title, topicID: draft.topicID, stage: draft.stage,
            startedAt: draft.sessionStart, endedAt: .now, answers: draft.answers, xp: xp, isStudy: draft.isStudy)
        if draft.isStudy == true {
            for answer in draft.answers where answer.correct {
                progress.vocabulary = progress.vocabulary ?? VocabularyProgressEG()
                progress.vocabulary?.reviewed[answer.question.id] = .now
            }
        }
        progress.history.append(record)
        markActivity()
        progress.draft = nil
        result = record
        signal(.completion)
        save()
    }
    func closeResult() { showingSession = false; result = nil }
    func retry(_ record: SessionRecordEG) {
        if let id = record.topicID, let topic = topics.first(where: { $0.id == id }), let stage = record.stage {
            start(topic, stage: stage)
        } else if record.isStudy == true { startVocabularyReview(reverse: false) }
        else { startReview() }
    }
    func configureReview(for topic: TopicEG? = nil) {
        selectedTopics = topic.map { [$0.id] } ?? Set(completedTopics.map(\.id))
        reviewDifficulty = settings.difficulty
    }
    func startReview() {
        guard session == nil else {
            errorMessage = L10nEG.string("Сначала завершите или удалите сохранённый тест в разделе «Учиться».")
            return
        }
        var random = SystemRandomNumberGenerator()
        let questions = ReviewGeneratorEG.generate(topics: topics, progress: progress, selected: selectedTopics,
            count: reviewCount, difficulty: reviewDifficulty, type: reviewType, using: &random)
        guard !questions.isEmpty else { return }
        var new = TestSessionEG(title: L10nEG.string("Повторение"), topicID: nil, stage: nil, questions: questions)
        new.prepareQuestion()
        progress.draft = new
        result = nil
        save()
        showingSession = true
    }
    var learnedWords: [VocabularyWordEG] {
        VocabularyWordEG.all.filter { progress.vocabulary?.learned[$0.id] != nil }
    }
    var newWords: [VocabularyWordEG] {
        VocabularyWordEG.all.filter { progress.vocabulary?.learned[$0.id] == nil }
    }
    var studyReviews: Int { progress.history.filter { $0.isStudy == true }.count }

    func learnWord(_ word: VocabularyWordEG) {
        guard VocabularyWordEG.all.contains(where: { $0.id == word.id }),
              progress.vocabulary?.learned[word.id] == nil else { return }
        progress.vocabulary = progress.vocabulary ?? VocabularyProgressEG()
        progress.vocabulary?.learned[word.id] = .now
        progress.vocabulary?.xp += 10
        markActivity()
        signal(.success)
        save()
    }

    func reviewWord(_ word: VocabularyWordEG) {
        guard progress.vocabulary?.learned[word.id] != nil else { return }
        let previous = progress.vocabulary?.reviewed[word.id]
        progress.vocabulary?.reviewed[word.id] = .now
        if previous.map({ Calendar.current.isDateInToday($0) }) != true {
            progress.vocabulary?.xp += 2
        }
        markActivity()
        signal(.success)
        save()
    }

    func startVocabularyReview(reverse: Bool) {
        guard session == nil else {
            errorMessage = L10nEG.string("Сначала завершите или удалите сохранённый тест в разделе «Учиться».")
            return
        }
        guard learnedWords.count >= 2 else { return }
        let count = [5, 10, 15][settings.difficulty.rawValue - 1]
        let words = learnedWords.sorted {
            (progress.vocabulary?.reviewed[$0.id] ?? .distantPast) < (progress.vocabulary?.reviewed[$1.id] ?? .distantPast)
        }.prefix(count)
        let questions = words.map { word in
            let correct = reverse ? word.word : word.translation
            let others = learnedWords.filter { $0.id != word.id }.shuffled().prefix(3)
                .map { reverse ? $0.word : $0.translation }
            return QuestionEG(id: word.id, topicID: "vocabulary", stage: .choice, kind: .multipleChoice,
                difficulty: 1, instruction: reverse ? L10nEG.string("Вспомнить английское слово") : L10nEG.string("Выбрать перевод"),
                prompt: reverse ? word.translation : word.word, options: ([correct] + others).shuffled(),
                answer: correct, tokens: [], explanation: word.example,
                skill: L10nEG.string("Словарный запас"))
        }
        var draft = TestSessionEG(title: L10nEG.string("Повторение слов"), topicID: nil, stage: nil, questions: questions)
        draft.isStudy = true
        draft.prepareQuestion()
        progress.draft = draft
        result = nil
        save()
        showingSession = true
    }

    func reset() {
        let keptSettings = progress.settings
        progress = UserProgressEG()
        progress.settings = keptSettings
        path = []
        result = nil
        showingSession = false
        selectedTopics = []
        tab = .learn
        save()
    }
    func save() {
        guard !startupFailed, !isLoading else { return }
        do { try persistence?.save(progress) }
        catch { errorMessage = L10nEG.string("Не удалось сохранить прогресс. Освободите место на устройстве и попробуйте снова.") }
    }
    func rankedTopics(weakest: Bool) -> [TopicEG] {
        completedTopics.filter { stats.topicAnswers($0.id).count >= 5 }.sorted {
            let left = stats.accuracy(for: stats.topicAnswers($0.id))
            let right = stats.accuracy(for: stats.topicAnswers($1.id))
            return left == right ? $0.order < $1.order : (weakest ? left < right : left > right)
        }
    }
    private func markActivity() {
        let today = Calendar.current.startOfDay(for: .now)
        if !progress.activityDays.contains(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            progress.activityDays.append(today)
        }
    }
    private func signal(_ kind: FeedbackEG.Kind) {
        feedback = FeedbackEG(kind: kind)
        if settings.sounds && kind != .selection { sound.play(success: kind != .error) }
    }
    private func populatePreview() {
        for topic in topics.prefix(3) {
            progress.topics[topic.id] = TopicProgressEG(completedStages: Set(0...4), bestScore: 93)
            let answers = topic.questions.prefix(15).enumerated().map { index, question in
                AnswerEG(id: UUID(), question: question, response: index == 3 ? question.options.last ?? question.answer : question.answer, correct: index != 3, date: .now)
            }
            progress.history.append(SessionRecordEG(id: UUID(), title: topic.title, topicID: topic.id, stage: .final,
                startedAt: .now, endedAt: .now, answers: answers, xp: 170))
        }
        progress.activityDays = (0..<3).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
        if let topic = topics.dropFirst(3).first { progress.topics[topic.id] = TopicProgressEG(completedStages: [0, 1]) }
    }
}

struct FeedbackEG: Equatable {
    enum Kind { case selection, success, error, completion }
    var id = UUID()
    var kind: Kind = .selection
}
