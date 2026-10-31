import Foundation
import Combine

@MainActor
final class StudyViewModelEG: ObservableObject {
    @Published var method: StudyMethodEG = .flashcards
    @Published var search = ""
    @Published private(set) var cards: [VocabularyWordEG] = []
    @Published private(set) var index = 0
    @Published private(set) var revealed = false
    @Published private(set) var completed = false
    @Published var showingCards = false

    var currentWord: VocabularyWordEG? { cards.indices.contains(index) ? cards[index] : nil }

    func startCards(words: [VocabularyWordEG]) {
        guard !words.isEmpty else { return }
        cards = words.shuffled()
        index = 0
        revealed = false
        completed = false
        showingCards = true
    }
    func reveal() { revealed = true }
    func advance(remembered: Bool, model: ViewModelEG) {
        guard revealed, let word = currentWord, !completed else { return }
        if remembered { model.reviewWord(word) }
        else { cards.append(word) }
        index += 1
        revealed = false
        completed = index == cards.count
    }
    func filteredWords(_ words: [VocabularyWordEG]) -> [VocabularyWordEG] {
        words.filter { search.isEmpty || $0.word.localizedStandardContains(search) || $0.translation.localizedStandardContains(search) }
            .sorted { $0.word.localizedStandardCompare($1.word) == .orderedAscending }
    }
}
