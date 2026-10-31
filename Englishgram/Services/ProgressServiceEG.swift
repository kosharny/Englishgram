import Foundation
import SwiftData

@MainActor
final class ProgressServiceEG {
    let container: ModelContainer
    private let context: ModelContext
    private var store: ProgressStoreEG?
    private var sessions: [UUID: SessionStoreEG] = [:]
    init(inMemory: Bool = false, url: URL? = nil) throws {
        let schema = Schema([ProgressStoreEG.self, SessionStoreEG.self])
        let configuration = if let url { ModelConfiguration(schema: schema, url: url) }
        else { ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory) }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        context.autosaveEnabled = false
    }
    func load() throws -> UserProgressEG {
        store = try context.fetch(FetchDescriptor<ProgressStoreEG>()).first
        var progress = try store.map { try JSONDecoder().decode(UserProgressEG.self, from: $0.payload) } ?? UserProgressEG()
        let records = try context.fetch(FetchDescriptor<SessionStoreEG>())
        sessions = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        let existingIDs = Set(progress.history.map(\.id))
        progress.history += try records.filter { !existingIDs.contains($0.id) }.map {
            try JSONDecoder().decode(SessionRecordEG.self, from: $0.payload)
        }
        progress.history.sort { $0.endedAt < $1.endedAt }
        return progress
    }
    func save(_ progress: UserProgressEG) throws {
        var snapshot = progress
        snapshot.history = []
        let data = try JSONEncoder().encode(snapshot)
        if let store { store.payload = data }
        else { let newStore = ProgressStoreEG(payload: data); context.insert(newStore); store = newStore }
        let retained = Set(progress.history.map(\.id))
        for (id, record) in sessions where !retained.contains(id) {
            context.delete(record)
            sessions.removeValue(forKey: id)
        }
        for record in progress.history where sessions[record.id] == nil {
            let stored = SessionStoreEG(id: record.id, payload: try JSONEncoder().encode(record))
            context.insert(stored)
            sessions[record.id] = stored
        }
        try context.save()
    }
}
