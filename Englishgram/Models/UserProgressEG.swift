import Foundation
import SwiftData

struct TopicProgressEG: Codable {
    var completedStages: Set<Int> = []
    var bestScore: Int = 0
    var completed: Bool { completedStages.contains(StageEG.final.rawValue) }
}

struct AnswerEG: Codable, Identifiable {
    let id: UUID
    let question: QuestionEG
    let response: String
    let correct: Bool
    let date: Date
}

struct SessionRecordEG: Codable, Identifiable {
    let id: UUID
    let title: String
    let topicID: String?
    let stage: StageEG?
    let startedAt: Date
    let endedAt: Date
    let answers: [AnswerEG]
    let xp: Int
    var correct: Int { answers.filter(\.correct).count }
    var percentage: Int { answers.isEmpty ? 0 : Int((Double(correct) / Double(answers.count) * 100).rounded()) }
    var bestRun: Int {
        var run = 0
        var best = 0
        for answer in answers { run = answer.correct ? run + 1 : 0; best = max(best, run) }
        return best
    }
    var isStudy: Bool? = nil
    var mistakes: [AnswerEG] { answers.filter { !$0.correct } }
}

struct SettingsEG: Codable {
    var sounds = true
    var haptics = true
    var explanations = true
    var difficulty: DifficultyEG = .normal
    var language: AppLanguageEG? = nil
    var appearance: AppearanceEG? = nil
    var appLanguage: AppLanguageEG {
        get { language ?? .system }
        set { language = newValue }
    }
    var appAppearance: AppearanceEG {
        get { appearance ?? .light }
        set { appearance = newValue }
    }
}

struct UserProgressEG: Codable {
    var topics: [String: TopicProgressEG] = [:]
    var history: [SessionRecordEG] = []
    var activityDays: [Date] = []
    var lectureXP = 0
    var settings = SettingsEG()
    var draft: TestSessionEG? = nil
    var vocabulary: VocabularyProgressEG? = nil
    var xp: Int { lectureXP + history.reduce(0) { $0 + $1.xp } + (vocabulary?.xp ?? 0) }
}

@Model
final class ProgressStoreEG {
    @Attribute(.unique) var key: String
    var payload: Data
    init(key: String = "englishgram-v1", payload: Data) {
        self.key = key
        self.payload = payload
    }
}

@Model
final class SessionStoreEG {
    @Attribute(.unique) var id: UUID
    var payload: Data
    init(id: UUID, payload: Data) {
        self.id = id
        self.payload = payload
    }
}
