import SwiftUI

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct ItemDetailSheet: View {
    let item: SavedItem
    @Environment(\.openURL) private var openURL
    @State private var detent: PresentationDetent = .medium

    private var destination: URL? {
        URL(string: item.url.hasPrefix("http") ? item.url : "https://" + item.url)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)

                HStack(spacing: 5) {
                    SourceIcon(domain: item.domain)
                    Text("\(item.domain) · saved \(item.savedAt.formatted(.relative(presentation: .numeric)))")
                        .font(.footnote)
                        .foregroundStyle(Color(.systemGray))
                }
                .padding(.top, 8)

                Button {
                    if let destination { openURL(destination) }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.up.right")
                            .font(.subheadline.weight(.semibold))
                        Text("Open Link")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(Color.primary, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 20)

                if let summary = item.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.subheadline.weight(.semibold))
                        Text(summary)
                            .font(.callout)
                            .fontDesign(.serif)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                }
            }
            .padding(.bottom, 48)
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-large") {
                detent = .large
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if item.hasThumbnail,
           let image = UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path) {
            Color.clear
                .aspectRatio(1.05, contentMode: .fit)
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
                .aspectRatio(1.6, contentMode: .fit)
                .overlay(
                    Text(item.title)
                        .font(.title3.weight(.medium))
                        .fontDesign(.serif)
                        .multilineTextAlignment(.center)
                        .padding(28)
                )
        }
    }
}
