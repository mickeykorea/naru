import SwiftUI

struct ShareSaveView: View {
    let loadURL: () async -> URL?
    let finish: () -> Void
    let cancel: () -> Void

    @StateObject private var store = ArchiveStore()
    @State private var url: URL?
    @State private var preview: LinkPreview?
    @State private var fetching = true
    @State private var noLink = false
    @State private var selectedCategory: String?
    @State private var newCategory = ""

    private let suggestions = ["Reads", "Watch", "Sounds", "Inspiration"]

    private var categoryChoices: [String] {
        store.categories.isEmpty ? suggestions : store.categories
    }

    private var chosenCategory: String? {
        let typed = newCategory.trimmingCharacters(in: .whitespaces)
        if !typed.isEmpty { return typed }
        return selectedCategory
    }

    private var canSave: Bool {
        url != nil && chosenCategory != nil && !fetching
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("Save to Naru")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.systemGray))
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray6), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 24)

            if noLink {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing to save here.")
                        .font(.system(size: 15, weight: .medium))
                    Text("Naru saves links — share a page or post with a URL.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.systemGray))
                }
            } else {
                previewRow

                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.systemGray))
                    FlowChips(choices: categoryChoices, selected: $selectedCategory)
                        .onChange(of: selectedCategory) { if selectedCategory != nil { newCategory = "" } }
                    TextField("Or create a new category…", text: $newCategory)
                        .submitLabel(.done)
                        .onChange(of: newCategory) { if !newCategory.isEmpty { selectedCategory = nil } }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6), in: Capsule())
                        .font(.system(size: 15))
                }

                Button(action: submit) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(canSave ? Color.primary : Color(.systemGray3), in: Capsule())
                }
                .disabled(!canSave)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .task {
            guard let incoming = await loadURL() else {
                noLink = true
                fetching = false
                return
            }
            url = incoming
            preview = await LinkMetadataFetcher.fetch(incoming.absoluteString)
            fetching = false
        }
    }

    private var previewRow: some View {
        HStack(spacing: 12) {
            Group {
                if let image = preview?.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray6)
                        .overlay {
                            if fetching { ProgressView() }
                            else { Image(systemName: "globe").foregroundStyle(Color(.systemGray)) }
                        }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(fetching ? "Fetching…" : (preview?.title ?? domain))
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                Text(domain)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.systemGray))
            }
            Spacer()
        }
    }

    private var domain: String {
        guard let host = url?.host else { return "web" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private func submit() {
        guard let url, let category = chosenCategory else { return }
        let title = preview?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = SavedItem(
            id: UUID(),
            url: url.absoluteString,
            title: (title?.isEmpty == false ? title! : domain),
            category: category,
            savedAt: .now,
            hasThumbnail: preview?.image != nil,
            summary: preview?.summary
        )
        if let image = preview?.image, let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: ArchiveStore.thumbnailURL(for: item.id))
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        store.add(item)
        finish()
    }
}
