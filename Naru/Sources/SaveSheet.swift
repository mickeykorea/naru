import SwiftUI

struct SaveSheet: View {
    let existingCategories: [String]
    let onSave: (SavedItem, UIImage?) -> Void

    @State private var draft = ""
    @State private var preview: LinkPreview?
    @State private var fetching = false
    @State private var selectedCategory: String?
    @State private var newCategory = ""
    @FocusState private var linkFocused: Bool
    @FocusState private var categoryFocused: Bool

    private let suggestions = ["Reads", "Watch", "Sounds", "Inspiration"]

    private var categoryChoices: [String] {
        existingCategories.isEmpty ? suggestions : existingCategories
    }

    private var chosenCategory: String? {
        let typed = newCategory.trimmingCharacters(in: .whitespaces)
        if !typed.isEmpty { return typed }
        return selectedCategory
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty && chosenCategory != nil && !fetching
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Save to Naru")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 24)

            TextField("Paste a link…", text: $draft)
                .focused($linkFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.next)
                .onSubmit { startFetch() }
                .onChange(of: draft) { startFetchDebounced() }
                .font(.system(size: 15))
                .padding(14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))

            if fetching || preview != nil {
                previewRow
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.systemGray))
                categoryPicker
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(430)])
        .presentationCornerRadius(24)
        .onAppear {
            if draft.isEmpty, let clip = UIPasteboard.general.string,
               clip.hasPrefix("http") {
                draft = clip
                startFetch()
            } else {
                linkFocused = true
            }
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
                Text(fetching ? "Fetching…" : (preview?.title ?? domainOf(draft)))
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                Text(domainOf(draft))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.systemGray))
            }
            Spacer()
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowChips(choices: categoryChoices, selected: $selectedCategory)
                .onChange(of: selectedCategory) { if selectedCategory != nil { newCategory = "" } }
            TextField("Or create a new category…", text: $newCategory)
                .focused($categoryFocused)
                .submitLabel(.done)
                .onChange(of: newCategory) { if !newCategory.isEmpty { selectedCategory = nil } }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6), in: Capsule())
                .font(.system(size: 15))
        }
    }

    private func domainOf(_ urlString: String) -> String {
        guard let host = URL(string: urlString.hasPrefix("http") ? urlString : "https://" + urlString)?.host else {
            return "web"
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    @State private var fetchTask: Task<Void, Never>?

    private func startFetchDebounced() {
        fetchTask?.cancel()
        fetchTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            startFetch()
        }
    }

    private func startFetch() {
        let url = draft.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else { return }
        fetching = true
        Task {
            let result = await LinkMetadataFetcher.fetch(url)
            preview = result
            fetching = false
        }
    }

    private func submit() {
        guard canSave, let category = chosenCategory else { return }
        let url = draft.trimmingCharacters(in: .whitespaces)
        let title = preview?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = SavedItem(
            id: UUID(),
            url: url,
            title: (title?.isEmpty == false ? title! : domainOf(url)),
            category: category,
            savedAt: .now,
            hasThumbnail: preview?.image != nil,
            summary: preview?.summary
        )
        onSave(item, preview?.image)
    }
}
