import SwiftUI

// Notes-style masonry card. Everything renders inside the surface —
// no title/metadata below the tile anymore.
struct SaveCard: View {
    enum Style { case text, inset, fullBleed }

    let item: SavedItem
    let style: Style
    var cropNudge: CGFloat = 1

    var body: some View {
        switch style {
        case .text: textCard
        case .inset: insetCard
        case .fullBleed: fullBleedCard
        }
    }

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            metaLine()
            title
            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(.garamond(15, .regular))
                    .foregroundStyle(Color(.systemGray))
                    .lineSpacing(4)
                    .lineLimit(Self.previewLineLimit(for: item))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(surface)
    }

    private var insetCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                metaLine()
                title
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            // literal overflow: the image runs 6pt past each side and out
            // the bottom; the card's own clip crops it
            overflowThumbnail(aspect: Self.insetAspect(for: item, nudge: cropNudge))
                .padding(.horizontal, -6)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var fullBleedCard: some View {
        thumbnail(aspect: Self.clampedAspect(for: item, in: 0.68...0.95), radius: 22)
            .overlay(
                // legibility scrim under the overlaid text, fading out by mid-card
                LinearGradient(colors: [.black.opacity(0.55), .black.opacity(0)],
                               startPoint: .top, endPoint: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    metaLine(tint: .white.opacity(0.85))
                    title.foregroundStyle(.white)
                }
                .padding(14)
            }
    }

    private var title: some View {
        Text(item.title)
            .font(.system(size: 17, weight: .bold))
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }

    private func metaLine(tint: Color = Color(.systemGray)) -> some View {
        HStack(spacing: 5) {
            SourceIcon(domain: item.domain, tint: tint)
            Text("\(SourceIcon.displayName(for: item.domain)) · \(Self.shortAge(item.savedAt))")
                .font(.system(size: 13))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
    }

    // "2w", "3d" — full relative phrases truncate beside long domains
    // in half-width cards
    static func shortAge(_ date: Date) -> String {
        date.formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
            .replacingOccurrences(of: " ago", with: "")
    }

    private var surface: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private func thumbnail(aspect: CGFloat, radius: CGFloat) -> some View {
        overflowThumbnail(aspect: aspect)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    private func overflowThumbnail(aspect: CGFloat) -> some View {
        Color.clear
            .aspectRatio(aspect, contentMode: .fit)
            .overlay {
                if let image = UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .clipped()
    }

    // uniform caps flatten the masonry — vary preview depth per item,
    // stably (UUID hashValue reseeds every launch; sum the string instead)
    static func previewLineLimit(for item: SavedItem) -> Int {
        let seed = item.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return [3, 5, 7][seed % 3]
    }

    // same-ratio sources (stock 3:2 shots) tie card heights — cycle the
    // fill-crop by masonry position so adjacent image cards always differ
    static let cropNudges: [CGFloat] = [0.78, 1.0, 1.22]

    static func insetAspect(for item: SavedItem, nudge: CGFloat) -> CGFloat {
        min(max((aspect(for: item) ?? 1) * nudge, 0.66), 1.5)
    }

    // hasThumbnail can lie (file pruned or never written) — style decisions
    // must check the JPEG actually loads, or a full-bleed card renders empty
    static func hasLoadableThumbnail(_ item: SavedItem) -> Bool {
        item.hasThumbnail && aspect(for: item) != nil
    }

    // Thumbnail aspect (w/h), read once from the stored JPEG
    private static var aspectCache: [UUID: CGFloat] = [:]

    private static func aspect(for item: SavedItem) -> CGFloat? {
        if let cached = aspectCache[item.id] { return cached }
        guard let image = UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path),
              image.size.height > 0 else { return nil }
        let aspect = image.size.width / image.size.height
        aspectCache[item.id] = aspect
        return aspect
    }

    static func clampedAspect(for item: SavedItem, in range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(aspect(for: item) ?? 1, range.lowerBound), range.upperBound)
    }
}

// Two-column staggered grid: items flow in order into whichever column is
// currently shorter, judged by rough height estimates — balance is the
// goal, not pixel accuracy.
struct MasonryGrid<Card: View>: View {
    let entries: [(item: SavedItem, style: SaveCard.Style)]
    @ViewBuilder let card: (SavedItem, SaveCard.Style, Int) -> Card

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            column(0)
            column(1)
        }
    }

    private func column(_ index: Int) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(columns[index], id: \.item.id) { entry in
                card(entry.item, entry.style, entry.position)
            }
        }
    }

    private var columns: [[(position: Int, item: SavedItem, style: SaveCard.Style)]] {
        var cols: [[(position: Int, item: SavedItem, style: SaveCard.Style)]] = [[], []]
        var heights: [CGFloat] = [0, 0]
        for (position, entry) in entries.enumerated() {
            let target = heights[0] <= heights[1] ? 0 : 1
            cols[target].append((position, entry.item, entry.style))
            heights[target] += estimatedHeight(entry.item, entry.style, position) + 12
        }
        return cols
    }

    private func estimatedHeight(_ item: SavedItem, _ style: SaveCard.Style, _ position: Int) -> CGFloat {
        let width: CGFloat = 170
        let titleHeight = CGFloat(min(3, item.title.count / 16 + 1)) * 22
        switch style {
        case .fullBleed:
            return width / SaveCard.clampedAspect(for: item, in: 0.68...0.95)
        case .inset:
            // overflowing image is 12pt wider than the card
            return 24 + 16 + 8 + titleHeight
                + (width + 12) / SaveCard.insetAspect(
                    for: item, nudge: SaveCard.cropNudges[position % 3])
        case .text:
            let previewLines = min(SaveCard.previewLineLimit(for: item),
                                   (item.summary?.count ?? 0) / 20)
            return 32 + 16 + 8 + titleHeight
                + (previewLines > 0 ? 8 + CGFloat(previewLines) * 21 : 0)
        }
    }
}

struct SourceIcon: View {
    let domain: String
    var tint: Color = Color(.systemGray)

    private static let brands: [(match: String, asset: String, name: String)] = [
        ("x.com", "brand-x", "x"), ("twitter", "brand-x", "x"),
        ("instagram", "brand-instagram", "instagram"), ("notion", "brand-notion", "notion"),
        ("spotify", "brand-spotify", "spotify"),
        ("youtube", "brand-youtube", "youtube"), ("youtu.be", "brand-youtube", "youtube"),
        ("reddit", "brand-reddit", "reddit"),
        ("pinterest", "brand-pinterest", "pinterest"), ("tiktok", "brand-tiktok", "tiktok"),
        ("github", "brand-github", "github"), ("medium.com", "brand-medium", "medium"),
        ("substack", "brand-substack", "substack"), ("netflix", "brand-netflix", "netflix"),
        ("figma", "brand-figma", "figma"), ("facebook", "brand-facebook", "facebook"),
        ("threads", "brand-threads", "threads"), ("t.me", "brand-telegram", "telegram"),
        ("telegram", "brand-telegram", "telegram"), ("whatsapp", "brand-whatsapp", "whatsapp"),
        ("twitch", "brand-twitch", "twitch"), ("soundcloud", "brand-soundcloud", "soundcloud"),
        ("apple.com", "brand-apple", "apple"), ("google", "brand-google", "google"),
        ("naver", "brand-naver", "naver"), ("kakao", "brand-kakaotalk", "kakao"),
        ("nytimes", "brand-newyorktimes", "nytimes"), ("dribbble", "brand-dribbble", "dribbble"),
        ("behance", "brand-behance", "behance"), ("vimeo", "brand-vimeo", "vimeo"),
    ]

    // known brands read by name; random weblinks keep their raw domain
    static func displayName(for domain: String) -> String {
        brands.first(where: { domain.contains($0.match) })?.name ?? domain
    }

    var body: some View {
        Group {
            if let asset = Self.brands.first(where: { domain.contains($0.match) })?.asset {
                Image(asset)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
            } else {
                // SF Symbol fills its frame; brand glyphs sit at 20/24 of
                // theirs — shrink the globe to the same round-class key height
                Image(systemName: "globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .frame(width: 12, height: 12)
            }
        }
        .foregroundStyle(tint)
    }
}
