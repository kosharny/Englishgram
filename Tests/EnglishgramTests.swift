import XCTest
import SwiftData
import SwiftUI
import UIKit
@testable import Englishgram

@MainActor
final class EnglishgramTests: XCTestCase {
    private func makeModel(url: URL? = nil) throws -> ViewModelEG {
        let topics = try CourseServiceEG.load(bundle: Bundle(for: ProgressStoreEG.self))
        let model = try ViewModelEG(topics: topics, persistence: ProgressServiceEG(inMemory: url == nil, url: url))
        model.settings.sounds = false
        return model
    }
    private func selectAnswer(_ model: ViewModelEG, correctly: Bool) throws {
        let session = try XCTUnwrap(model.session)
        if session.question.kind.usesTokens {
            if correctly {
                var used = Set<Int>()
                for token in session.question.answer.trimmingCharacters(in: CharacterSet(charactersIn: ".!?")).split(separator: " ").map(String.init) {
                    let index = try XCTUnwrap(session.tokenOrder.indices.first { !used.contains($0) && session.tokenOrder[$0] == token })
                    used.insert(index)
                    model.toggleToken(index)
                }
            } else { model.toggleToken(0) }
        } else {
            let response = correctly ? session.question.answer : try XCTUnwrap(session.optionOrder.first { $0 != session.question.answer })
            model.select(response)
        }
    }
    private func answer(_ model: ViewModelEG, correctly: Bool) throws {
        try selectAnswer(model, correctly: correctly)
        model.check()
        model.next()
    }
    private func finish(_ model: ViewModelEG, correctCount: Int = .max) throws {
        var count = 0
        while model.session != nil {
            try answer(model, correctly: count < correctCount)
            count += 1
            XCTAssertLessThan(count, 100)
        }
    }
    private func prepareFinal(_ model: ViewModelEG, topic: TopicEG) throws {
        model.completeLecture(topic)
        for stage in [StageEG.choice, .translation, .practice] {
            model.start(topic, stage: stage)
            try finish(model)
            model.closeResult()
        }
    }
    func testCourseIntegrityAndFinalIsolation() async throws {
        let model = try makeModel()
        XCTAssertEqual(model.topics.count, 20)
        let questions = model.topics.flatMap(\.questions)
        XCTAssertEqual(questions.count, 980)
        XCTAssertEqual(Set(questions.map(\.id)).count, 980)
        for topic in model.topics {
            XCTAssertGreaterThanOrEqual(topic.lecture.count, 19)
            XCTAssertTrue(topic.lecture.contains { $0.kind == .checkpoint })
            XCTAssertGreaterThanOrEqual(topic.questions.filter { $0.kind.usesTokens }.count, 26)
            for stage in [StageEG.choice, .translation, .practice, .final] {
                XCTAssertEqual(topic.questions.filter { $0.stage == stage }.count, stage == .final ? 17 : stage == .practice ? 12 : 10)
            }
            let training = Set(topic.questions.filter { $0.stage != .final }.map(\.prompt))
            XCTAssertTrue(training.isDisjoint(with: topic.questions.filter { $0.stage == .final }.map(\.prompt)))
            for question in topic.questions {
                XCTAssertFalse(question.explanation.isEmpty)
                if question.kind.usesTokens {
                    var available = question.tokens
                    for token in question.answer.trimmingCharacters(in: CharacterSet(charactersIn: ".!?")).split(separator: " ").map(String.init) {
                        let index = try XCTUnwrap(available.firstIndex(of: token))
                        available.remove(at: index)
                    }
                } else {
                    XCTAssertEqual(question.options.filter { $0 == question.answer }.count, 1)
                    XCTAssertEqual(Set(question.options).count, question.options.count)
                }
            }
        }
    }
    func testInitialStateAndStageGates() async throws {
        let model = try makeModel()
        XCTAssertEqual(model.topics.filter(model.isUnlocked).map(\.order), [1])
        XCTAssertEqual(model.progress.xp, 0)
        XCTAssertTrue(model.completedTopics.isEmpty)
        XCTAssertEqual(model.stats.streak(), 0)
        let topic = try XCTUnwrap(model.topics.first)
        model.start(topic, stage: .final)
        XCTAssertNil(model.session)
        model.completeLecture(model.topics[1])
        XCTAssertTrue(model.progress.topics.isEmpty)
        model.completeLecture(topic)
        XCTAssertTrue(model.canStart(.choice, topic: topic))
        XCTAssertFalse(model.canStart(.translation, topic: topic))
        XCTAssertEqual(model.progress.xp, 20)
        model.completeLecture(topic)
        XCTAssertEqual(model.progress.xp, 20)
    }
    func testAllTopicsCanCompleteWithTheirAnswerTokens() async throws {
        let model = try makeModel()
        for topic in model.topics {
            XCTAssertTrue(model.isUnlocked(topic))
            try prepareFinal(model, topic: topic)
            model.start(topic, stage: .final)
            try finish(model)
            XCTAssertEqual(model.result?.percentage, 100)
            XCTAssertTrue(model.topicProgress(topic).completed)
            model.closeResult()
        }
        XCTAssertEqual(model.completedTopics.count, 20)
        XCTAssertNil(model.currentTopic)
        XCTAssertEqual(model.currentLevel, "B1")
        XCTAssertEqual(model.progress.history.count, 80)
        XCTAssertEqual(model.stats.answers.count, 980)
    }
    func testFailedFinalThenPassingRetakeAndBestScore() async throws {
        let model = try makeModel()
        let topic = model.topics[0]
        try prepareFinal(model, topic: topic)
        model.start(topic, stage: .final)
        try finish(model, correctCount: 11)
        XCTAssertEqual(model.result?.percentage, 65)
        XCTAssertFalse(model.topicProgress(topic).completed)
        XCTAssertFalse(model.isUnlocked(model.topics[1]))
        model.start(topic, stage: .final)
        try finish(model, correctCount: 12)
        XCTAssertEqual(model.result?.percentage, 71)
        XCTAssertTrue(model.isUnlocked(model.topics[1]))
        model.start(topic, stage: .final)
        try finish(model, correctCount: 17)
        model.start(topic, stage: .final)
        try finish(model, correctCount: 0)
        XCTAssertEqual(model.topicProgress(topic).bestScore, 100)
        XCTAssertTrue(model.isUnlocked(model.topics[1]))
    }
    func testDiskPersistenceForLectureDraftCompletionAndReset() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.store")
        var model = try makeModel(url: url)
        let topic = model.topics[0]
        model.completeLecture(topic)
        model.start(topic, stage: .choice)
        try answer(model, correctly: true)
        let id = model.session?.id
        model = try makeModel(url: url)
        XCTAssertTrue(model.topicProgress(topic).completedStages.contains(0))
        XCTAssertEqual(model.session?.id, id)
        XCTAssertEqual(model.session?.currentQuestionIndex, 1)
        XCTAssertEqual(model.session?.answers.count, 1)
        try finish(model)
        model.start(topic, stage: .translation)
        let draft = try XCTUnwrap(model.session)
        model.toggleToken(0)
        model = try makeModel(url: url)
        XCTAssertEqual(model.session?.tokenOrder, draft.tokenOrder)
        XCTAssertEqual(model.session?.constructedSentence, [0])
        model.toggleToken(0)
        try finish(model)
        model.start(topic, stage: .practice)
        try finish(model)
        model.start(topic, stage: .final)
        try finish(model, correctCount: 16)
        model = try makeModel(url: url)
        XCTAssertTrue(model.isUnlocked(model.topics[1]))
        XCTAssertEqual(model.topicProgress(topic).bestScore, 94)
        XCTAssertEqual(model.progress.history.count, 4)
        model.reset()
        model = try makeModel(url: url)
        XCTAssertEqual(model.topics.filter(model.isUnlocked).count, 1)
        XCTAssertEqual(model.progress.xp, 0)
        XCTAssertTrue(model.progress.history.isEmpty)
        XCTAssertNil(model.session)
        XCTAssertTrue(model.progress.activityDays.isEmpty)
    }
    func testReviewFiltersUniqueQuestionsAndFallback() async throws {
        let model = try makeModel()
        var progress = model.progress
        for topic in model.topics.prefix(3) { progress.topics[topic.id] = TopicProgressEG(completedStages: Set(0...4)) }
        for count in [5, 10, 15, 20] {
            for type in ReviewTypeEG.allCases {
                for difficulty in DifficultyEG.allCases {
                    var random = SeededEG(seed: 42)
                    let questions = ReviewGeneratorEG.generate(topics: model.topics, progress: progress,
                        selected: Set(model.topics.map(\.id)), count: count, difficulty: difficulty, type: type, using: &random)
                    XCTAssertEqual(questions.count, count)
                    XCTAssertEqual(Set(questions.map(\.id)).count, count)
                    XCTAssertEqual(Set(questions.map { $0.prompt + "|" + $0.answer }).count, count)
                    XCTAssertTrue(questions.allSatisfy { progress.topics[$0.topicID]?.completed == true })
                    XCTAssertTrue(questions.allSatisfy(type.matches))
                }
            }
        }
        var random = SeededEG(seed: 17)
        let one = ReviewGeneratorEG.generate(topics: model.topics, progress: progress,
            selected: [model.topics[0].id], count: 20, difficulty: .easy, type: .choice, using: &random)
        XCTAssertEqual(one.count, 20)
        XCTAssertEqual(Set(one.map(\.id)).count, 20)
        XCTAssertTrue(one.allSatisfy { $0.topicID == model.topics[0].id })
        let none = ReviewGeneratorEG.generate(topics: model.topics, progress: model.progress,
            selected: Set(model.topics.map(\.id)), count: 20, difficulty: .normal, type: .mixed, using: &random)
        XCTAssertTrue(none.isEmpty)
    }
    func testRenderScreensAtSmallAndLargeSizes() async throws {
        let model = try makeModel()
        let topic = model.topics[0]
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Englishgram-QA")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        func render<V: View>(_ view: V, name: String, width: CGFloat, height: CGFloat, size: DynamicTypeSize = .large) throws {
            let content = view.frame(width: width, height: height)
                .environment(\.locale, Locale(identifier: "ru"))
                .environment(\.dynamicTypeSize, size).environment(\.colorScheme, .light)
                .tint(PaletteEG.navy).background(PaletteEG.background).ignoresSafeArea()
            let host = UIHostingController(rootView: content)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat()
            format.scale = 2
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                host.view.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            let pixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
            XCTAssertGreaterThan(Set(stride(from: 0, to: pixels.count, by: 97).map { pixels[$0] }).count, 20, "Snapshot must contain rendered content")
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            let data = try XCTUnwrap(image.pngData())
            let file = directory.appendingPathComponent(name + ".png")
            try data.write(to: file)
            print("SNAPSHOT_EG: \(file.path)")
        }
        try render(LaunchViewEG(animatesEntrance: false), name: "launch", width: 390, height: 760)
        try render(LaunchViewEG(animatesEntrance: false), name: "launch-small", width: 375, height: 580, size: .xxxLarge)
        try render(MainViewEG(model: model), name: "learn-first-run", width: 390, height: 760)
        try render(TopicDetailViewEG(model: model, topic: topic), name: "topic", width: 390, height: 760)
        try render(LessonViewEG(model: model, topic: topic), name: "lecture", width: 390, height: 760)
        try render(LearnViewEG(model: model), name: "learn-small-large-type", width: 375, height: 600, size: .xxxLarge)
        if let checkpoint = topic.lecture.first(where: { $0.kind == .checkpoint }) {
            try render(LessonBlockViewEG(block: checkpoint).padding(20), name: "checkpoint", width: 390, height: 400)
        }
        model.completeLecture(topic)
        model.start(topic, stage: .choice)
        try render(ActiveTestViewEG(model: model, session: XCTUnwrap(model.session), close: {}), name: "question", width: 390, height: 760)
        model.discard()
        try prepareFinal(model, topic: topic)
        model.start(topic, stage: .translation)
        try render(ActiveTestViewEG(model: model, session: XCTUnwrap(model.session), close: {}), name: "translation", width: 390, height: 760)
        model.discard()
        model.start(topic, stage: .final)
        try finish(model, correctCount: 13)
        let record = try XCTUnwrap(model.result)
        try render(ResultViewEG(model: model, result: record), name: "result", width: 390, height: 760)
        model.configureReview()
        try render(ReviewViewEG(model: model), name: "review", width: 390, height: 760)
        try render(ProgressViewEG(model: model), name: "progress", width: 390, height: 760)
        for language in [AppLanguageEG.pl, .uk] {
            model.settings.appLanguage = language
            try render(StudyViewEG(model: model).environment(\.locale, L10nEG.locale), name: "study-" + language.rawValue, width: 390, height: 760)
        }
        for word in VocabularyWordEG.all.prefix(3) { model.learnWord(word) }
        try render(LearnedWordsViewEG(model: model).environment(\.locale, L10nEG.locale), name: "learned-words", width: 375, height: 600, size: .xxxLarge)
        try render(StudyViewEG(model: model).environment(\.locale, L10nEG.locale).environment(\.colorScheme, .dark), name: "study-dark", width: 390, height: 760)
        try render(SettingsViewEG(model: model).environment(\.locale, L10nEG.locale), name: "settings-uk", width: 390, height: 760)
        model.settings.appLanguage = .ru
    }
    func testDuplicateCheckAndResumeDoesNotLoseAnswers() async throws {
        let model = try makeModel()
        model.completeLecture(model.topics[0])
        model.start(model.topics[0], stage: .choice)
        let question = try XCTUnwrap(model.session?.question)
        try selectAnswer(model, correctly: true)
        model.check()
        model.check()
        XCTAssertEqual(model.session?.answers.count, 1)
        model.pause()
        model.start(model.topics[0], stage: .choice)
        XCTAssertTrue(model.session?.checked == true)
        XCTAssertEqual(TestSessionEG.normalize(model.session?.response ?? ""), TestSessionEG.normalize(question.answer))
        model.next()
        XCTAssertEqual(model.session?.currentQuestionIndex, 1)
    }
    func testDeferredLaunchLoadsOnceWithoutResettingState() async throws {
        let model = ViewModelEG(loadImmediately: false)
        XCTAssertTrue(model.isLoading)
        XCTAssertTrue(model.topics.isEmpty)
        await model.loadIfNeeded()
        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.startupFailed)
        XCTAssertEqual(model.topics.count, 20)
        let topicIDs = model.topics.map(\.id)
        model.tab = .progress
        await model.loadIfNeeded()
        XCTAssertEqual(model.topics.map(\.id), topicIDs)
        XCTAssertEqual(model.tab, .progress)
    }
    func testLegacyDraftSurvivesCourseExpansion() async throws {
        let store = try ProgressServiceEG(inMemory: true)
        let topics = try CourseServiceEG.load(bundle: Bundle(for: ProgressStoreEG.self))
        let model = try ViewModelEG(topics: topics, persistence: store)
        model.settings.sounds = false
        let topic = topics[0]
        model.completeLecture(topic)
        let legacyQuestions = Array(topic.questions.prefix(8))
        var draft = TestSessionEG(title: topic.title, topicID: topic.id, stage: .choice, questions: legacyQuestions)
        draft.prepareQuestion()
        model.progress.draft = draft
        try answer(model, correctly: true)
        model.save()
        let restored = try ViewModelEG(topics: topics, persistence: store)
        XCTAssertEqual(restored.session?.questions.count, 8)
        XCTAssertEqual(restored.session?.currentQuestionIndex, 1)
        try finish(restored)
        XCTAssertTrue(restored.canStart(.translation, topic: topic))
        restored.closeResult()
        restored.start(topic, stage: .choice)
        XCTAssertEqual(restored.session?.questions.count, 10)
    }
    func testStudyLearningRewardsPersistenceAndReset() async throws {
        let store = try ProgressServiceEG(inMemory: true)
        let model = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
        model.settings.sounds = false
        let word = VocabularyWordEG.all[0]
        model.learnWord(word)
        model.learnWord(word)
        XCTAssertEqual(model.learnedWords.map(\.id), [word.id])
        XCTAssertEqual(model.progress.xp, 10)
        XCTAssertEqual(model.stats.streak(), 1)
        XCTAssertEqual(model.progress.activityDays.count, 1)
        model.reviewWord(word)
        model.reviewWord(word)
        XCTAssertEqual(model.progress.xp, 12)
        let restored = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
        XCTAssertEqual(restored.learnedWords.map(\.id), [word.id])
        XCTAssertEqual(restored.progress.xp, 12)
        XCTAssertNotNil(restored.progress.vocabulary?.reviewed[word.id])
        restored.settings.appLanguage = .pl
        restored.settings.appAppearance = .dark
        restored.reset()
        XCTAssertTrue(restored.learnedWords.isEmpty)
        XCTAssertEqual(restored.progress.xp, 0)
        XCTAssertEqual(restored.settings.appLanguage, .pl)
        XCTAssertEqual(restored.settings.appAppearance, .dark)
        L10nEG.language = .ru
    }

    func testStudyQuizBothDirectionsAndDraftProtection() async throws {
        let model = try makeModel()
        model.startVocabularyReview(reverse: false)
        XCTAssertNil(model.session)
        for word in VocabularyWordEG.all.prefix(6) { model.learnWord(word) }
        for reverse in [false, true] {
            model.startVocabularyReview(reverse: reverse)
            let draft = try XCTUnwrap(model.session)
            XCTAssertEqual(draft.isStudy, true)
            XCTAssertEqual(draft.questions.count, 6)
            XCTAssertEqual(Set(draft.questions.map(\.id)).count, 6)
            for question in draft.questions {
                let word = try XCTUnwrap(model.learnedWords.first { $0.id == question.id })
                XCTAssertEqual(question.prompt, reverse ? word.translation : word.word)
                XCTAssertEqual(question.answer, reverse ? word.word : word.translation)
                XCTAssertTrue(question.options.contains(question.answer))
                XCTAssertEqual(Set(question.options).count, question.options.count)
            }
            model.startVocabularyReview(reverse: !reverse)
            XCTAssertEqual(model.session?.id, draft.id)
            model.errorMessage = nil
            try finish(model)
            XCTAssertEqual(model.result?.isStudy, true)
            XCTAssertEqual(model.result?.percentage, 100)
            model.closeResult()
        }
        XCTAssertEqual(model.studyReviews, 2)
        XCTAssertEqual(model.stats.reviews, 0)
        XCTAssertEqual(model.stats.answers.count, 12)
        XCTAssertEqual(model.progress.activityDays.count, 1)
    }

    func testFlashcardsRepeatMissedWordsAndFilterTranslations() async throws {
        let model = try makeModel()
        let study = StudyViewModelEG()
        let word = VocabularyWordEG.all[0]
        model.learnWord(word)
        study.startCards(words: [word])
        study.advance(remembered: true, model: model)
        XCTAssertEqual(study.index, 0)
        study.reveal()
        study.advance(remembered: false, model: model)
        XCTAssertFalse(study.completed)
        XCTAssertEqual(study.currentWord?.id, word.id)
        XCTAssertNil(model.progress.vocabulary?.reviewed[word.id])
        study.reveal()
        study.advance(remembered: true, model: model)
        XCTAssertTrue(study.completed)
        XCTAssertNotNil(model.progress.vocabulary?.reviewed[word.id])
        study.search = word.translation
        XCTAssertEqual(study.filteredWords(model.learnedWords).count, 1)
        study.search = "nothing-matches"
        XCTAssertTrue(study.filteredWords(model.learnedWords).isEmpty)
    }

    func testLegacyPayloadDecodesWithoutNewSettingsOrVocabulary() async throws {
        let model = try makeModel()
        let encoded = try JSONEncoder().encode(model.progress)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "vocabulary")
        var settings = try XCTUnwrap(json["settings"] as? [String: Any])
        settings.removeValue(forKey: "language")
        settings.removeValue(forKey: "appearance")
        json["settings"] = settings
        let decoded = try JSONDecoder().decode(UserProgressEG.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.vocabulary)
        XCTAssertEqual(decoded.settings.appLanguage, .system)
        XCTAssertEqual(decoded.settings.appAppearance, .light)
        XCTAssertEqual(decoded.xp, 0)
    }

    func testLanguageSwitchLocalizesCourseDraftAndStoredHistory() async throws {
        let model = try makeModel()
        model.settings.appLanguage = .ru
        let topic = model.topics[0]
        model.completeLecture(topic)
        model.start(topic, stage: .choice)
        try answer(model, correctly: true)
        let id = model.session?.id
        let instructions = try XCTUnwrap(model.session?.question.instruction)
        let prompt = model.session?.question.prompt
        let xp = model.progress.xp
        for language in [AppLanguageEG.pl, .uk] {
            model.settings.appLanguage = language
            XCTAssertEqual(L10nEG.language, language)
            XCTAssertNotEqual(model.session?.question.instruction, instructions)
            XCTAssertEqual(model.session?.question.prompt, prompt)
            XCTAssertEqual(model.session?.id, id)
            XCTAssertEqual(model.session?.answers.count, 1)
            XCTAssertEqual(model.progress.xp, xp)
            XCTAssertEqual(model.topics[0].lecture[0].title, language == .pl ? "Co to jest?" : "Що це таке?")
        }
        model.settings.appLanguage = .ru
        XCTAssertEqual(model.session?.question.instruction, instructions)
        try finish(model)
        let record = try XCTUnwrap(model.progress.history.first)
        model.settings.appLanguage = .pl
        XCTAssertNotEqual(model.progress.history.first?.answers.first?.question.instruction,
                          record.answers.first?.question.instruction)
        XCTAssertEqual(model.progress.history.first?.id, record.id)
        model.settings.appLanguage = .ru
        XCTAssertEqual(model.progress.history.first?.answers.first?.question.instruction,
                       record.answers.first?.question.instruction)
    }

    func testLocalizedTrueFalseAnswerSurvivesLanguageSwitchAndReload() async throws {
        let store = try ProgressServiceEG(inMemory: true)
        let model = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
        model.settings.sounds = false
        model.settings.appLanguage = .ru
        let question = try XCTUnwrap(model.topics[0].questions.first { $0.kind == .trueFalse })
        var draft = TestSessionEG(title: model.topics[0].title, topicID: model.topics[0].id,
                                  stage: .practice, questions: [question])
        draft.prepareQuestion()
        model.progress.draft = draft
        model.select(question.answer)
        model.check()
        for language in [AppLanguageEG.pl, .uk, .ru] {
            model.settings.appLanguage = language
            let current = try XCTUnwrap(model.session)
            XCTAssertEqual(current.selectedAnswer, current.question.answer)
            XCTAssertTrue(current.optionOrder.contains(current.question.answer))
            XCTAssertTrue(current.answers[0].correct)
            XCTAssertEqual(current.answers[0].response, current.answers[0].question.answer)
            let restored = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
            XCTAssertEqual(restored.session?.selectedAnswer, current.question.answer)
            XCTAssertEqual(restored.session?.id, current.id)
        }
    }

    func testEveryCourseStringHasBothOfflineTranslations() async throws {
        let bundle = Bundle(for: ProgressStoreEG.self)
        let url = try XCTUnwrap(bundle.url(forResource: "CourseTranslationsEG", withExtension: "json"))
        let translations = try JSONDecoder().decode([String: [String: String]].self, from: Data(contentsOf: url))
        var sources = Set<String>()
        func collect(_ value: Any) {
            if let string = value as? String, string.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil {
                sources.insert(string)
            } else if let array = value as? [Any] { array.forEach(collect) }
            else if let dictionary = value as? [String: Any] { dictionary.values.forEach(collect) }
        }
        for name in ["A1CourseEG", "A2CourseEG", "B1CourseEG"] {
            let file = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json"))
            collect(try JSONSerialization.jsonObject(with: Data(contentsOf: file)))
        }
        XCTAssertGreaterThan(sources.count, 1600)
        for language in [AppLanguageEG.pl, .uk] {
            let values = try XCTUnwrap(translations[language.rawValue])
            XCTAssertTrue(sources.allSatisfy { values[$0]?.isEmpty == false })
            L10nEG.language = language
            let topics = try CourseServiceEG.load(bundle: bundle)
            XCTAssertEqual(topics.flatMap(\.questions).count, 980)
        }
        L10nEG.language = .ru
    }

    func testPreferencePersistenceAndDifficultyAppliesImmediately() async throws {
        let store = try ProgressServiceEG(inMemory: true)
        let model = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
        model.settings.sounds = false
        model.settings.haptics = false
        model.settings.explanations = false
        model.settings.difficulty = .hard
        model.settings.appAppearance = .dark
        model.settings.appLanguage = .uk
        XCTAssertEqual(model.reviewDifficulty, .hard)
        let restored = try ViewModelEG(topics: CourseServiceEG.load(), persistence: store)
        XCTAssertFalse(restored.settings.sounds)
        XCTAssertFalse(restored.settings.haptics)
        XCTAssertFalse(restored.settings.explanations)
        XCTAssertEqual(restored.settings.appLanguage, .uk)
        XCTAssertEqual(restored.settings.appAppearance, .dark)
        XCTAssertEqual(restored.reviewDifficulty, .hard)
        XCTAssertEqual(L10nEG.string("Настройки"), "Налаштування")
        L10nEG.language = .ru
    }

    func testNormalizationPreservesGrammar() async {
        XCTAssertEqual(TestSessionEG.normalize("  She   works here.  "), TestSessionEG.normalize("she works here"))
        XCTAssertEqual(TestSessionEG.normalize("He isn’t busy!"), TestSessionEG.normalize("he isn't busy"))
        XCTAssertNotEqual(TestSessionEG.normalize("She work here"), TestSessionEG.normalize("She works here"))
    }
    func testStreakAcrossDatesAndDuplicateDays() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 12)))
        var progress = UserProgressEG()
        progress.activityDays = [0, 0, -1, -2].compactMap { calendar.date(byAdding: .day, value: $0, to: now) }
        XCTAssertEqual(StatisticsEG(progress: progress).streak(now: now, calendar: calendar), 3)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: now))
        XCTAssertEqual(StatisticsEG(progress: progress).streak(now: tomorrow, calendar: calendar), 3)
        let later = try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: now))
        XCTAssertEqual(StatisticsEG(progress: progress).streak(now: later, calendar: calendar), 0)
    }
}

private struct SeededEG: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 { seed = 2862933555777941757 &* seed &+ 3037000493; return seed }
}
