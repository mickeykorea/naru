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
    var onNoteChange: (String) -> Void = { _ in }
    @Environment(\.openURL) private var openURL
    @State private var detent: PresentationDetent = .medium
    @State private var note: String = ""
    @State private var scrollY: CGFloat = 0

    private let heroTopInset: CGFloat = 34
    private let minHeroHeight: CGFloat = 120

    private var destination: URL? {
        URL(string: item.url.hasPrefix("http") ? item.url : "https://" + item.url)
    }

    private var heroImage: UIImage? {
        guard item.hasThumbnail else { return nil }
        return UIImage(contentsOfFile: ArchiveStore.thumbnailURL(for: item.id).path)
    }

    var body: some View {
        GeometryReader { geo in
            let aspect: CGFloat = heroImage != nil ? 1.05 : 1.6
            let fullHero = (geo.size.width - 24) / aspect
            // 1:1 with the finger: the hero gives up exactly the scrolled
            // distance until it hits the floor, so its bottom edge and the
            // content stay glued together through the collapse
            let heroHeight = max(minHeroHeight, fullHero - max(0, scrollY))

            ScrollView {
                content
                    .padding(.top, heroTopInset + fullHero)
                    .padding(.bottom, 48)
            }
            .onScrollGeometryChange(
                for: CGFloat.self,
                of: { $0.contentOffset.y + $0.contentInsets.top }
            ) { _, y in
                scrollY = y
            }
            .overlay(alignment: .top) {
                hero
                    .frame(height: heroHeight)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 12)
                    .padding(.top, heroTopInset)
                    .frame(maxWidth: .infinity)
                    // opaque shield: content scrolls under the pinned hero
                    .background(Color(.systemBackground))
                    .accessibilityIdentifier("detail-hero")
            }
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        // the default sheet background is translucent glass at .medium,
        // which reads as a different color than the hero's opaque shield
        .presentationBackground(Color(.systemBackground))
        // custom grabber, lower than the system's 5pt (matches the Genie
        // reference; the 28pt corner radius needs the extra air)
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
        }
        .onAppear {
            note = item.note ?? ""
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-large") {
                detent = .large
            }
            #endif
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Text(item.title)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 24)

            HStack(spacing: 5) {
                SourceIcon(domain: item.domain)
                Text("\(item.domain) · saved \(item.savedAt.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.systemGray))
            }
            .padding(.top, 8)

            Button {
                if let destination { openURL(destination) }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Open Link")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.systemBackground))
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Color.primary, in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("NOTE")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Color(.systemGray))
                TextField("Add a note…", text: $note, axis: .vertical)
                    .font(.garamond(17))
                    .lineLimit(1...6)
                    .submitLabel(.done)
                    .onChange(of: note) { onNoteChange(note) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)

            if let summary = item.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUMMARY")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.6)
                        .foregroundStyle(Color(.systemGray))
                    Text(summary)
                        .font(.garamond(17))
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 36)
            }
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let image = heroImage {
            Color.clear
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
                .overlay(
                    Text(item.title)
                        .font(.garamond(23, .medium))
                        .multilineTextAlignment(.center)
                        .padding(28)
                )
        }
    }
}
