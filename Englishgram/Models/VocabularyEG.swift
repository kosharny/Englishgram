import Foundation

struct VocabularyWordEG: Identifiable, Codable {
    let id: String
    let word: String
    let ru: String
    let pl: String
    let uk: String
    let example: String

    var translation: String {
        switch L10nEG.language.code {
        case "pl": pl
        case "uk": uk
        default: ru
        }
    }

    static let all: [Self] = [
        .init(id: "hello", word: "hello", ru: "привет", pl: "cześć", uk: "привіт", example: "Hello, how are you?"),
        .init(id: "friend", word: "friend", ru: "друг", pl: "przyjaciel", uk: "друг", example: "She is my best friend."),
        .init(id: "family", word: "family", ru: "семья", pl: "rodzina", uk: "сім’я", example: "My family lives here."),
        .init(id: "home", word: "home", ru: "дом", pl: "dom", uk: "дім", example: "I am going home."),
        .init(id: "water", word: "water", ru: "вода", pl: "woda", uk: "вода", example: "Can I have some water?"),
        .init(id: "food", word: "food", ru: "еда", pl: "jedzenie", uk: "їжа", example: "The food is delicious."),
        .init(id: "book", word: "book", ru: "книга", pl: "książka", uk: "книга", example: "I am reading a book."),
        .init(id: "learn", word: "learn", ru: "учиться", pl: "uczyć się", uk: "вчитися", example: "We learn something every day."),
        .init(id: "work", word: "work", ru: "работать", pl: "pracować", uk: "працювати", example: "I work in a small office."),
        .init(id: "travel", word: "travel", ru: "путешествовать", pl: "podróżować", uk: "подорожувати", example: "They love to travel."),
        .init(id: "morning", word: "morning", ru: "утро", pl: "poranek", uk: "ранок", example: "I run every morning."),
        .init(id: "evening", word: "evening", ru: "вечер", pl: "wieczór", uk: "вечір", example: "See you this evening."),
        .init(id: "today", word: "today", ru: "сегодня", pl: "dzisiaj", uk: "сьогодні", example: "Today is a good day."),
        .init(id: "tomorrow", word: "tomorrow", ru: "завтра", pl: "jutro", uk: "завтра", example: "I will call you tomorrow."),
        .init(id: "happy", word: "happy", ru: "счастливый", pl: "szczęśliwy", uk: "щасливий", example: "She looks happy."),
        .init(id: "beautiful", word: "beautiful", ru: "красивый", pl: "piękny", uk: "гарний", example: "What a beautiful garden!"),
        .init(id: "important", word: "important", ru: "важный", pl: "ważny", uk: "важливий", example: "This is an important question."),
        .init(id: "easy", word: "easy", ru: "лёгкий", pl: "łatwy", uk: "легкий", example: "This exercise is easy."),
        .init(id: "difficult", word: "difficult", ru: "трудный", pl: "trudny", uk: "складний", example: "It was a difficult decision."),
        .init(id: "always", word: "always", ru: "всегда", pl: "zawsze", uk: "завжди", example: "He always arrives on time."),
        .init(id: "sometimes", word: "sometimes", ru: "иногда", pl: "czasami", uk: "іноді", example: "Sometimes we eat outside."),
        .init(id: "never", word: "never", ru: "никогда", pl: "nigdy", uk: "ніколи", example: "I never drink coffee at night."),
        .init(id: "understand", word: "understand", ru: "понимать", pl: "rozumieć", uk: "розуміти", example: "Do you understand the question?"),
        .init(id: "remember", word: "remember", ru: "помнить", pl: "pamiętać", uk: "пам’ятати", example: "I remember your name."),
        .init(id: "think", word: "think", ru: "думать", pl: "myśleć", uk: "думати", example: "I think you are right."),
        .init(id: "speak", word: "speak", ru: "говорить", pl: "mówić", uk: "говорити", example: "We speak English together."),
        .init(id: "listen", word: "listen", ru: "слушать", pl: "słuchać", uk: "слухати", example: "Please listen carefully."),
        .init(id: "write", word: "write", ru: "писать", pl: "pisać", uk: "писати", example: "Write a short sentence."),
        .init(id: "read", word: "read", ru: "читать", pl: "czytać", uk: "читати", example: "I read before bed."),
        .init(id: "improve", word: "improve", ru: "улучшать", pl: "poprawiać", uk: "покращувати", example: "Practice helps you improve.")
    ]
}

struct VocabularyProgressEG: Codable {
    var learned: [String: Date] = [:]
    var reviewed: [String: Date] = [:]
    var xp = 0
}

enum StudyMethodEG: String, CaseIterable, Identifiable {
    case flashcards, translation, reverse
    var id: String { rawValue }
    var title: String {
        switch self {
        case .flashcards: L10nEG.string("Карточки")
        case .translation: L10nEG.string("Выбрать перевод")
        case .reverse: L10nEG.string("Вспомнить английское слово")
        }
    }
}
