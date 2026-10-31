import Foundation

struct TestSessionEG: Codable, Identifiable {
    var isStudy: Bool? = nil
    var id = UUID()
    let title: String
    let topicID: String?
    let stage: StageEG?
    var questions: [QuestionEG]
    var currentQuestionIndex = 0
    var selectedAnswer: String? = nil
    var constructedSentence: [Int] = []
    var answers: [AnswerEG] = []
    var sessionStart = Date()
    var checked = false
    var optionOrder: [String] = []
    var tokenOrder: [String] = []
    var question: QuestionEG { questions[currentQuestionIndex] }
    var response: String { question.kind.usesTokens ? constructedSentence.map { tokenOrder[$0] }.joined(separator: " ") : selectedAnswer ?? "" }
    var canCheck: Bool { !checked && !response.isEmpty }
    var isLast: Bool { currentQuestionIndex == questions.count - 1 }
    var answeredQuestionIDs: Set<String> { Set(answers.map { $0.question.id }) }
    mutating func prepareQuestion() {
        selectedAnswer = nil
        constructedSentence = []
        checked = false
        optionOrder = question.options.shuffled()
        tokenOrder = question.tokens.shuffled()
    }
    mutating func check(now: Date = .now) {
        guard canCheck, !answeredQuestionIDs.contains(question.id) else { return }
        answers.append(AnswerEG(id: UUID(), question: question, response: response,
                                correct: Self.normalize(response) == Self.normalize(question.answer), date: now))
        checked = true
    }
    static func normalize(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".!?")))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
