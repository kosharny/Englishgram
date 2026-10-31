import Foundation

struct StatisticsEG {
    let progress: UserProgressEG
    var answers: [AnswerEG] { progress.history.flatMap(\.answers) }
    var accuracy: Int { accuracy(for: answers) }
    var reviews: Int { progress.history.filter { $0.stage == nil && $0.isStudy != true }.count }
    func accuracy(for answers: [AnswerEG]) -> Int {
        answers.isEmpty ? 0 : Int((Double(answers.filter(\.correct).count) / Double(answers.count) * 100).rounded())
    }
    func topicAnswers(_ id: String) -> [AnswerEG] { answers.filter { $0.question.topicID == id } }
    func streak(now: Date = .now, calendar: Calendar = .current) -> Int {
        let days = Set(progress.activityDays.map { calendar.startOfDay(for: $0) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
