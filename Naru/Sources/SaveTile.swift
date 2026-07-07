import SwiftUI

struct SaveTile: View {
    let item: SavedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            tile
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    SourceIcon(domain: item.domain)
                    Text("\(item.domain) · \(item.savedAt.formatted(.relative(presentation: .numeric)))")
                        .font(.footnote)
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
                        .font(.subheadline.weight(.medium))
                        .fontDesign(.serif)
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

    var body: some View {
        AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
            default:
                Image(systemName: "globe")
                    .resizable()
                    .foregroundStyle(Color(.systemGray))
            }
        }
        .frame(width: 13, height: 13)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
