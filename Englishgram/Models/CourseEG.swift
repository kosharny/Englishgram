import Foundation

struct TopicEG: Codable, Identifiable, Hashable {
    let id: String
    let order: Int
    let title: String
    let level: String
    let subtitle: String
    let minutes: Int
    let lecture: [LessonBlockEG]
    let questions: [QuestionEG]
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LessonBlockEG: Codable, Identifiable {
    let id: String
    let kind: Kind
    let title: String
    let text: String
    var detail: String? = nil
    enum Kind: String, Codable { case text, formula, example, tip, mistake, words, summary, checkpoint }
}

enum StageEG: Int, Codable, CaseIterable, Identifiable {
    case lecture, choice, translation, practice, final
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .lecture: L10nEG.string("Лекция")
        case .choice: L10nEG.string("Базовая тренировка")
        case .translation: L10nEG.string("Перевод")
        case .practice: L10nEG.string("Практика")
        case .final: L10nEG.string("Финальный тест")
        }
    }
    var icon: String {
        switch self {
        case .lecture: "book.closed.fill"
        case .choice: "checkmark.circle.fill"
        case .translation: "character.book.closed.fill"
        case .practice: "pencil.and.list.clipboard"
        case .final: "flag.checkered"
        }
    }
    var xp: Int { [20, 30, 40, 50, 100][rawValue] }
}

enum QuestionKindEG: String, Codable {
    case multipleChoice, translation, wordOrder, makeNegative, makeQuestion, findMistake, trueFalse, ruleCompletion, changePerson, shortAnswer, combineSentences
    var usesTokens: Bool { [.translation, .wordOrder, .makeNegative, .makeQuestion, .changePerson, .shortAnswer, .combineSentences].contains(self) }
}

struct QuestionEG: Codable, Identifiable {
    let id: String
    let topicID: String
    let stage: StageEG
    let kind: QuestionKindEG
    let difficulty: Int
    let instruction: String
    let prompt: String
    let options: [String]
    let answer: String
    let tokens: [String]
    let explanation: String
    let skill: String
}

enum TabEG: String, CaseIterable, Identifiable {
    case learn, review, study, progress
    var id: String { rawValue }
    var title: String {
        switch self {
        case .learn: L10nEG.string("Учиться")
        case .review: L10nEG.string("Повторение")
        case .study: L10nEG.string("Изучение")
        case .progress: L10nEG.string("Прогресс")
        }
    }
    var icon: String {
        switch self {
        case .learn: "map.fill"
        case .review: "arrow.triangle.2.circlepath"
        case .study: "rectangle.on.rectangle.angled"
        case .progress: "chart.bar.fill"
        }
    }
}

enum DifficultyEG: Int, Codable, CaseIterable, Identifiable {
    case easy = 1, normal, hard
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .easy: L10nEG.string("Легко")
        case .normal: L10nEG.string("Обычно")
        case .hard: L10nEG.string("Сложно")
        }
    }
    var detail: String {
        switch self {
        case .easy: L10nEG.string("Выбор ответа и простые предложения")
        case .normal: L10nEG.string("Сбалансированная смесь заданий")
        case .hard: L10nEG.string("Больше перевода и работы с ошибками")
        }
    }
}

enum ReviewTypeEG: Int, CaseIterable, Identifiable {
    case mixed, choice, translation, practice
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .mixed: L10nEG.string("Смешанный")
        case .choice: L10nEG.string("Выбор ответа")
        case .translation: L10nEG.string("Перевод")
        case .practice: L10nEG.string("Практика")
        }
    }
    func matches(_ question: QuestionEG) -> Bool {
        switch self {
        case .mixed: true
        case .choice: question.kind == .multipleChoice
        case .translation: question.kind == .translation
        case .practice: ![.multipleChoice, .translation].contains(question.kind)
        }
    }
}
