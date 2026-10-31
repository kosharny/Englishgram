import Foundation

struct ReviewGeneratorEG {
    static func generate<R: RandomNumberGenerator>(topics: [TopicEG], progress: UserProgressEG,
        selected: Set<String>, count: Int, difficulty: DifficultyEG, type: ReviewTypeEG, using random: inout R) -> [QuestionEG] {
        let learned = topics.filter { progress.topics[$0.id]?.completed == true && selected.contains($0.id) }
        var signatures = Set<String>()
        let pool = learned.flatMap(\.questions).filter {
            signatures.insert(TestSessionEG.normalize($0.prompt) + "|" + TestSessionEG.normalize($0.answer)).inserted
        }
        let matching = pool.filter(type.matches)
        let candidates = matching.count >= count ? matching : matching + pool.filter { !type.matches($0) }
        let history = progress.history.flatMap(\.answers)
        let byTopic = Dictionary(grouping: history, by: { $0.question.topicID })
        let failed = Set(history.filter { !$0.correct }.suffix(50).map { $0.question.id })
        return candidates.map { question -> (QuestionEG, Double) in
            let answers = byTopic[question.topicID] ?? []
            let accuracy = answers.isEmpty ? 0 : Double(answers.filter(\.correct).count) / Double(answers.count)
            var weight = accuracy >= 0.9 ? 1.0 : accuracy >= 0.75 ? 2.0 : 3.0
            if failed.contains(question.id) { weight *= 1.5 }
            if question.difficulty == difficulty.rawValue { weight *= 3 }
            if type.matches(question) { weight *= 4 }
            return (question, -log(Double.random(in: 0.000001...1, using: &random)) / weight)
        }.sorted { $0.1 < $1.1 }.prefix(count).map(\.0)
    }
}
