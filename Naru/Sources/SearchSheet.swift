import SwiftUI

struct SearchSheet: View {
    let items: [SavedItem]
    var onNoteChange: (UUID, String) -> Void = { _, _ in }
    @State private var query = ""
    @State private var selectedItem: SavedItem?
    @FocusState private var focused: Bool

    private var results: [SavedItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { item in
            item.title.lowercased().contains(q)
                || item.domain.lowercased().contains(q)
                || item.category.lowercased().contains(q)
                || (item.summary?.lowercased().contains(q) ?? false)
                || (item.note?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(.systemGray))
                TextField("Search your archive…", text: $query)
                    .focused($focused)
                    .font(.system(size: 15))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.systemGray3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
            .padding(.top, 28)

            if results.isEmpty {
                VStack(spacing: 6) {
                    Text("No matches.")
                        .font(.system(size: 15, weight: .medium))
                    Text("Titles, sources, categories, summaries, and notes are searched.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.systemGray))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)],
                              alignment: .leading, spacing: 24) {
                        ForEach(results) { item in
                            Button { selectedItem = item } label: {
                                SaveTile(item: item)
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityIdentifier("search-result")
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .padding(.horizontal, 20)
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.hidden)
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item) { onNoteChange(item.id, $0) }
        }
        .onAppear { focused = true }
    }
}
