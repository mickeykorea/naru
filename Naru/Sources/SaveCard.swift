import SwiftUI

// Notes-style masonry card. Everything renders inside the surface —
// no title/metadata below the tile anymore.
struct SaveCard: View {
    enum Style { case text, inset, fullBleed }

    let item: SavedItem
    let style: Style

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
                    .lineLimit(6)
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
            // glass-slab thumbnail: bleeds to a 5pt inset so its radius
            // runs concentric with the card's 22
            thumbnail(aspect: Self.clampedAspect(for: item, in: 0.75...1.3), radius: 17)
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(surface)
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
        Color.clear
            .aspectRatio(aspect, contentMode: .fit)
            .overlay {
                if let image = UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            // glass-slab rim, hand-built: glassEffect(.clear) overlaid on the
            // image blurs the whole thumbnail (tried, rejected) — a gradient
            // specular stroke gives the lensed edge and keeps the image crisp
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.6),
                                                .white.opacity(0.08),
                                                .white.opacity(0.28)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
            }
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
    @ViewBuilder let card: (SavedItem, SaveCard.Style) -> Card

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            column(0)
            column(1)
        }
    }

    private func column(_ index: Int) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(columns[index], id: \.item.id) { entry in
                card(entry.item, entry.style)
            }
        }
    }

    private var columns: [[(item: SavedItem, style: SaveCard.Style)]] {
        var cols: [[(item: SavedItem, style: SaveCard.Style)]] = [[], []]
        var heights: [CGFloat] = [0, 0]
        for entry in entries {
            let target = heights[0] <= heights[1] ? 0 : 1
            cols[target].append(entry)
            heights[target] += estimatedHeight(entry.item, entry.style) + 12
        }
        return cols
    }

    private func estimatedHeight(_ item: SavedItem, _ style: SaveCard.Style) -> CGFloat {
        let width: CGFloat = 170
        let titleHeight = CGFloat(min(3, item.title.count / 16 + 1)) * 22
        switch style {
        case .fullBleed:
            return width / SaveCard.clampedAspect(for: item, in: 0.68...0.95)
        case .inset:
            return 28 + 16 + 8 + titleHeight + 8
                + width / SaveCard.clampedAspect(for: item, in: 0.75...1.3)
        case .text:
            let previewLines = min(6, (item.summary?.count ?? 0) / 20)
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
