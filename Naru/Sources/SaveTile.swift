import SwiftUI

struct SaveTile: View {
    let item: SavedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tile
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    SourceIcon(domain: item.domain)
                    Text("\(item.domain) · \(item.savedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.systemGray))
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var tile: some View {
        if item.hasThumbnail,
           let image = UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
        } else {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemGray6))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                )
        }
    }
}

struct SourceIcon: View {
    let domain: String

    private static let brands: [(match: String, asset: String)] = [
        ("x.com", "brand-x"), ("twitter", "brand-x"),
        ("instagram", "brand-instagram"), ("notion", "brand-notion"),
        ("spotify", "brand-spotify"),
        ("youtube", "brand-youtube"), ("youtu.be", "brand-youtube"),
        ("reddit", "brand-reddit"),
        ("pinterest", "brand-pinterest"), ("tiktok", "brand-tiktok"),
        ("github", "brand-github"), ("medium.com", "brand-medium"),
        ("substack", "brand-substack"), ("netflix", "brand-netflix"),
        ("figma", "brand-figma"), ("facebook", "brand-facebook"),
        ("threads", "brand-threads"), ("t.me", "brand-telegram"),
        ("telegram", "brand-telegram"), ("whatsapp", "brand-whatsapp"),
        ("twitch", "brand-twitch"), ("soundcloud", "brand-soundcloud"),
        ("apple.com", "brand-apple"), ("google", "brand-google"),
        ("naver", "brand-naver"), ("kakao", "brand-kakaotalk"),
        ("nytimes", "brand-newyorktimes"), ("dribbble", "brand-dribbble"),
        ("behance", "brand-behance"), ("vimeo", "brand-vimeo"),
    ]

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
        .foregroundStyle(Color(.systemGray))
    }
}
