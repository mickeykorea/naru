import ImageIO
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
            // Notes-ref slab: gutters + own top radius, but the bottom runs
            // 20pt past the card and the card's clip cuts it — with a
            // progressive blur at the cut edge so the image reads as
            // continuing beneath
            overflowThumbnail(aspect: Self.insetAspect(for: item, nudge: cropNudge))
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20,
                                                  topTrailingRadius: 20,
                                                  style: .continuous))
                .overlay(alignment: .bottom) {
                    VariableBlurView(maxBlurRadius: 7, flipped: true)
                        .frame(height: 56)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, -20)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var fullBleedCard: some View {
        thumbnail(aspect: Self.clampedAspect(for: item, in: Self.fullBleedAspectRange), radius: 22)
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

    // "2w", "3d" — full relative phrases truncate beside long domains in
    // half-width cards. Pinned to en_US: the suffix strip is English-only
    // and all app copy is unlocalized English anyway.
    static func shortAge(_ date: Date) -> String {
        var style = Date.RelativeFormatStyle(presentation: .numeric, unitsStyle: .narrow)
        style.locale = Locale(identifier: "en_US")
        return date.formatted(style).replacingOccurrences(of: " ago", with: "")
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

    static func cropNudge(at position: Int) -> CGFloat {
        cropNudges[position % cropNudges.count]
    }

    static let fullBleedAspectRange: ClosedRange<CGFloat> = 0.68...0.95

    static func insetAspect(for item: SavedItem, nudge: CGFloat) -> CGFloat {
        min(max((aspect(for: item) ?? 1) * nudge, 0.66), 1.5)
    }

    // hasThumbnail can lie (file pruned or never written) — style decisions
    // must check the JPEG actually loads, or a full-bleed card renders empty
    static func hasLoadableThumbnail(_ item: SavedItem) -> Bool {
        item.hasThumbnail && aspect(for: item) != nil
    }

    // Thumbnail aspect (w/h) from the JPEG header only — no bitmap decode.
    // 0 is the known-missing sentinel: without it, every item whose file is
    // absent would re-hit the filesystem on each body evaluation.
    private static var aspectCache: [UUID: CGFloat] = [:]

    static func invalidateAspect(for id: UUID) {
        aspectCache[id] = nil
    }

    private static func aspect(for item: SavedItem) -> CGFloat? {
        if let cached = aspectCache[item.id] { return cached == 0 ? nil : cached }
        let url = ArchiveStore.thumbnailURL(for: item.id)
        guard let source = CGImageSourceCreateWithURL(url as CFURL,
                  [kCGImageSourceShouldCache: false] as CFDictionary),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = props[kCGImagePropertyPixelHeight] as? CGFloat,
              height > 0 else {
            aspectCache[item.id] = 0
            return nil
        }
        let aspect = width / height
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
        // computed once — evaluating `columns` per column ran the O(n)
        // balance loop twice on every body evaluation
        let cols = columns
        HStack(alignment: .top, spacing: 12) {
            column(cols[0])
            column(cols[1])
        }
    }

    private func column(_ entries: [(position: Int, item: SavedItem, style: SaveCard.Style)]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(entries, id: \.item.id) { entry in
                card(entry.item, entry.style, entry.position)
            }
        }
        // equal share even when empty: an unframed empty column collapses
        // and the other stretches its cards across the full width
        .frame(maxWidth: .infinity)
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
            return width / SaveCard.clampedAspect(for: item, in: SaveCard.fullBleedAspectRange)
        case .inset:
            // image is 24pt narrower than the card; 20pt of it is cut off
            return 24 + 16 + 8 + titleHeight - 20
                + (width - 24) / SaveCard.insetAspect(
                    for: item, nudge: SaveCard.cropNudge(at: position))
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

    // registrable domains only — matched host == domain or host ends in
    // ".domain". Substring matching let fakeapple.com wear Apple's icon and
    // name while the real domain went unshown (spoofing surface).
    private static let brands: [(domain: String, asset: String, name: String)] = [
        ("x.com", "brand-x", "x"), ("twitter.com", "brand-x", "x"),
        ("instagram.com", "brand-instagram", "instagram"),
        ("notion.so", "brand-notion", "notion"), ("notion.site", "brand-notion", "notion"),
        ("spotify.com", "brand-spotify", "spotify"),
        ("youtube.com", "brand-youtube", "youtube"), ("youtu.be", "brand-youtube", "youtube"),
        ("reddit.com", "brand-reddit", "reddit"),
        ("pinterest.com", "brand-pinterest", "pinterest"), ("tiktok.com", "brand-tiktok", "tiktok"),
        ("github.com", "brand-github", "github"), ("medium.com", "brand-medium", "medium"),
        ("substack.com", "brand-substack", "substack"), ("netflix.com", "brand-netflix", "netflix"),
        ("figma.com", "brand-figma", "figma"), ("facebook.com", "brand-facebook", "facebook"),
        ("threads.net", "brand-threads", "threads"), ("threads.com", "brand-threads", "threads"),
        ("t.me", "brand-telegram", "telegram"), ("telegram.org", "brand-telegram", "telegram"),
        ("whatsapp.com", "brand-whatsapp", "whatsapp"),
        ("twitch.tv", "brand-twitch", "twitch"), ("soundcloud.com", "brand-soundcloud", "soundcloud"),
        ("apple.com", "brand-apple", "apple"), ("google.com", "brand-google", "google"),
        ("naver.com", "brand-naver", "naver"), ("kakao.com", "brand-kakaotalk", "kakao"),
        ("nytimes.com", "brand-newyorktimes", "nytimes"), ("dribbble.com", "brand-dribbble", "dribbble"),
        ("behance.net", "brand-behance", "behance"), ("vimeo.com", "brand-vimeo", "vimeo"),
    ]

    static func brand(for domain: String) -> (domain: String, asset: String, name: String)? {
        let host = domain.lowercased()
        return brands.first { host == $0.domain || host.hasSuffix("." + $0.domain) }
    }

    // known brands read by name; random weblinks keep their raw domain
    static func displayName(for domain: String) -> String {
        brand(for: domain)?.name ?? domain
    }

    var body: some View {
        Group {
            if let asset = Self.brand(for: domain)?.asset {
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
