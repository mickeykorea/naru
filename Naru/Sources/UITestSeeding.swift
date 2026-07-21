#if DEBUG
import UIKit

// Deterministic fixture archive for UI tests. Storage is already
// redirected by the presence of "-naru-uitest-seed" (see ArchiveStore),
// so seeding wipes and fills only the parallel test archive. The seed id
// is remembered: relaunches within one test keep their mutations
// (persistence tests), while a different id starts clean.
extension ArchiveStore {

    private static let seedMarkerKey = "naru.uitest.seedID"

    static func seedIfNeeded(_ seedID: String) {
        let defaults = SharedStorage.defaults
        guard defaults.string(forKey: seedMarkerKey) != seedID else { return }

        try? FileManager.default.removeItem(at: thumbnailDirectory)

        let day: TimeInterval = 86400
        let items = [
            // items[0] sits top-left in the masonry and is what
            // -naru-demo-detail opens: thumbnail hero + a summary long
            // enough that the large-detent sheet scrolls (hero collapse)
            SavedItem(id: UUID(), url: "https://essays.example.org/libraries",
                      title: "What We Owe Our Libraries", category: "Reading",
                      savedAt: Date().addingTimeInterval(-3 * day),
                      hasThumbnail: true,
                      summary: "Public libraries quietly underwrite the whole "
                          + "civic experiment: they are the last indoor spaces "
                          + "where nobody expects you to buy anything, staffed "
                          + "by people whose entire job is to hand you the "
                          + "means of changing your own mind. The essay traces "
                          + "the branch system from Carnegie's bargain through "
                          + "the quiet expansion of services — tool lending, "
                          + "tax help, air conditioning in heat waves — and "
                          + "argues that the metric that matters was never "
                          + "circulation but refuge. What would it cost to "
                          + "build this today, and would any city council "
                          + "approve it? The author's answer is uncomfortable "
                          + "and convincing, and the closing section on school "
                          + "libraries is worth the whole read on its own.",
                      summaryUpgraded: true),
            SavedItem(id: UUID(), url: "https://open.spotify.com/album/charm",
                      title: "Charm", category: "Music",
                      savedAt: Date().addingTimeInterval(-8 * day),
                      hasThumbnail: false,
                      summary: "Clairo's third record trades bedroom pop for "
                          + "a warm analog band sound — Wurlitzer, flute, and "
                          + "drums that sit way back in the room.",
                      summaryUpgraded: true),
            SavedItem(id: UUID(), url: "https://www.apple.com",
                      title: "Apple", category: "Tech",
                      savedAt: Date().addingTimeInterval(-12 * day),
                      hasThumbnail: false,
                      summary: "Landing page for hardware announcements and "
                          + "the seasonal lineup refresh.",
                      summaryUpgraded: true),
            SavedItem(id: UUID(), url: "https://open.spotify.com/playlist/jeju",
                      title: "Jeju Cassette, Side B — Night Drive Mix",
                      category: "Music",
                      savedAt: Date().addingTimeInterval(-15 * day),
                      hasThumbnail: false,
                      summary: "Coastal road playlist: city pop, tape hiss, "
                          + "and one song that only makes sense after midnight.",
                      summaryUpgraded: true),
            SavedItem(id: UUID(), url: "https://www.youtube.com/watch?v=deepsea",
                      title: "The deep sea is darker than you think",
                      category: "Watch",
                      savedAt: Date().addingTimeInterval(-20 * day),
                      hasThumbnail: false,
                      summary: "Below 1,000 meters, sunlight gives up "
                          + "entirely. This documentary follows the creatures "
                          + "that never see it.",
                      summaryUpgraded: true),
        ]

        writeThumbnail(for: items[0].id)
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: key)
        }
        defaults.set(seedID, forKey: seedMarkerKey)
    }

    // a generated gradient stands in for a real og:image — the tests only
    // need a decodable JPEG with a stable portrait aspect
    private static func writeThumbnail(for id: UUID) {
        let size = CGSize(width: 840, height: 1120)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(white: 0.35, alpha: 1).cgColor,
                          UIColor(white: 0.75, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(),
                                      colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(
                gradient, start: .zero,
                end: CGPoint(x: 0, y: size.height), options: [])
        }
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: thumbnailURL(for: id))
        }
    }
}
#endif
