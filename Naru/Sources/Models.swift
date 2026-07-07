import Foundation

struct SavedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    var title: String
    var category: String
    let savedAt: Date
    var hasThumbnail: Bool
    var summary: String?

    var domain: String {
        guard let host = URL(string: url.hasPrefix("http") ? url : "https://" + url)?.host else {
            return "web"
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

@MainActor
final class ArchiveStore: ObservableObject {
    @Published private(set) var items: [SavedItem] = []

    private let key = "naru.archive.v2"

    static var thumbnailDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func thumbnailURL(for id: UUID) -> URL {
        thumbnailDirectory.appendingPathComponent("\(id.uuidString).jpg")
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([SavedItem].self, from: data) {
            items = saved
        }
    }

    func add(_ item: SavedItem) {
        items.insert(item, at: 0)
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

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
