import Foundation

struct CourseServiceEG {
    static func load(bundle: Bundle = .main) throws -> [TopicEG] {
        let topics = try ["A1CourseEG", "A2CourseEG", "B1CourseEG"].flatMap { name -> [TopicEG] in
            guard let url = bundle.url(forResource: name, withExtension: "json") else { throw CourseError.missing(name) }
            return try JSONDecoder().decode([TopicEG].self, from: L10nEG.localizeJSON(Data(contentsOf: url)))
        }.sorted { $0.order < $1.order }
        guard !topics.isEmpty, Set(topics.map(\.id)).count == topics.count else { throw CourseError.invalid }
        for topic in topics {
            guard !topic.lecture.isEmpty else { throw CourseError.invalid }
            for stage in [StageEG.choice, .translation, .practice, .final] {
                guard topic.questions.filter({ $0.stage == stage }).count >= (stage == .final ? 15 : 8) else { throw CourseError.invalid }
            }
            for q in topic.questions {
                guard q.topicID == topic.id, !q.explanation.isEmpty, !q.answer.isEmpty,
                      q.kind.usesTokens ? !q.tokens.isEmpty : q.options.contains(q.answer) else { throw CourseError.invalid }
            }
        }
        return topics
    }
    enum CourseError: Error { case missing(String), invalid }
}
