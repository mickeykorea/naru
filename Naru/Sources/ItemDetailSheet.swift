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
    var categories: [String] = []
    var onNoteChange: (String) -> Void = { _ in }
    var onCategoryChange: (String) -> Void = { _ in }
    @Environment(\.openURL) private var openURL
    @State private var detent: PresentationDetent = .medium
    @State private var note: String = ""
    @State private var category: String = ""
    @State private var showNewCategory = false
    @State private var newCategoryName = ""
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

    private var heroShield: some View {
        #if DEBUG
        Color(.systemBackground)
            .accessibilityElement()
            .accessibilityIdentifier("detail-hero")
        #else
        Color(.systemBackground)
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let aspect: CGFloat = heroImage != nil ? 1.05 : 1.6
            let fullHero = (geo.size.width - 24) / aspect
            // 1:1 with the finger: the hero gives up exactly the scrolled
            // distance until it hits the floor, so its bottom edge and the
            // content stay glued together through the collapse
            let heroHeight = max(minHeroHeight, fullHero - max(0, scrollY))
            // after the hero bottoms out at its floor, stop pinning it: lift
            // it by the distance scrolled past the collapse so it rides up
            // with the content instead of the text sliding underneath
            let heroLift = -max(0, scrollY - (fullHero - minHeroHeight))

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
                    // opaque shield: content scrolls under the pinned hero.
                    // In DEBUG it also carries the test identifier — the
                    // image stack reports a11y frames as the union of
                    // children, and the fill image overflows its clip, so
                    // portrait heroes measure at a fixed, wrong height.
                    // Release builds skip it: it would be an unlabeled
                    // VoiceOver stop.
                    .background(heroShield)
                    .offset(y: heroLift)
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
        .alert("New Category", isPresented: $showNewCategory) {
            TextField("Name", text: $newCategoryName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { newCategoryName = "" }
            Button("Move") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    category = trimmed
                    onCategoryChange(trimmed)
                }
                newCategoryName = ""
            }
        } message: {
            Text("Move this save to a new category.")
        }
        .onAppear {
            note = item.note ?? ""
            category = item.category
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
                Text("Category")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.systemGray))
                Menu {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            category = cat
                            onCategoryChange(cat)
                        } label: {
                            if cat == category {
                                Label(cat, systemImage: "checkmark")
                            } else {
                                Text(cat)
                            }
                        }
                    }
                    Divider()
                    Button {
                        showNewCategory = true
                    } label: {
                        Label("New Category…", systemImage: "plus")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(category)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color(.systemGray6), in: Capsule())
                }
                .tint(.primary)
                .accessibilityIdentifier("category-pill")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)

            VStack(alignment: .leading, spacing: 12) {
                Text("Note")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.systemGray))
                TextField("Add a note…", text: $note, axis: .vertical)
                    .font(.garamond(17))
                    .lineLimit(1...6)
                    .submitLabel(.done)
                    .accessibilityIdentifier("detail-note")
                    .onChange(of: note) { onNoteChange(note) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 36)

            if let summary = item.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.system(size: 15, weight: .semibold))
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
