import Foundation

struct SavedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    var title: String
    var category: String
    let savedAt: Date
    var hasThumbnail: Bool
    var summary: String?
    var note: String? = nil
    // false = still carrying the publisher og:description; the app
    // upgrades these through Summarizer when it gets the chance
    var summaryUpgraded: Bool? = nil

    var domain: String {
        guard let host = URL(string: url.hasPrefix("http") ? url : "https://" + url)?.host else {
            return "web"
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

// Storage lives in the app group so the share extension and the app see
// the same archive. Falls back to per-app storage if the group container
// is unavailable (missing entitlement — should not happen in practice).
enum SharedStorage {
    static let appGroup = "group.com.mickeyoh.naru"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

@MainActor
final class ArchiveStore: ObservableObject {
    @Published private(set) var items: [SavedItem] = []

    private static let key = "naru.archive.v2"

    static var thumbnailDirectory: URL {
        let dir = SharedStorage.containerURL
            .appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func thumbnailURL(for id: UUID) -> URL {
        thumbnailDirectory.appendingPathComponent("\(id.uuidString).jpg")
    }

    init() {
        migrateFromStandardDefaultsIfNeeded()
        reload()
    }

    func reload() {
        if let data = SharedStorage.defaults.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([SavedItem].self, from: data) {
            if saved != items { items = saved }
        }
    }

    func add(_ item: SavedItem) {
        items.insert(item, at: 0)
        persist()
    }

    // used by the app-only summary sweep (ArchiveStore+Summaries.swift);
    // lives here because extensions cannot add stored properties
    var upgradingSummaries = false

    func setNote(_ note: String, for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].note = note.isEmpty ? nil : note
        persist()
    }

    func setCategory(_ category: String, for id: UUID) {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].category = trimmed
        persist()
    }

    func remove(_ item: SavedItem) {
        items.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: Self.thumbnailURL(for: item.id))
        persist()
    }

    var categories: [String] {
        var seen = [String]()
        for item in items where !seen.contains(item.category) { seen.append(item.category) }
        return seen
    }

    func mutate(_ change: (inout [SavedItem]) -> Void) {
        change(&items)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            SharedStorage.defaults.set(data, forKey: Self.key)
        }
    }

    // Builds 1-2 stored the archive in standard defaults and thumbnails in
    // Documents; carry those saves into the shared container once.
    private func migrateFromStandardDefaultsIfNeeded() {
        guard SharedStorage.defaults != UserDefaults.standard,
              SharedStorage.defaults.data(forKey: Self.key) == nil,
              let legacy = UserDefaults.standard.data(forKey: Self.key) else { return }
        SharedStorage.defaults.set(legacy, forKey: Self.key)

        let oldDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thumbnails", isDirectory: true)
        let newDir = Self.thumbnailDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.moveItem(
                    at: file,
                    to: newDir.appendingPathComponent(file.lastPathComponent))
            }
        }
    }
}
