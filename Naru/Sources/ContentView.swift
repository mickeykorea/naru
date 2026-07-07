import SwiftUI

struct SavedLink: Identifiable, Codable {
    let id: UUID
    let url: String
    let savedAt: Date
}

final class Inbox: ObservableObject {
    @Published private(set) var links: [SavedLink] = []

    private let key = "naru.inbox"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([SavedLink].self, from: data) {
            links = saved
        }
    }

    func add(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        links.insert(SavedLink(id: UUID(), url: trimmed, savedAt: .now), at: 0)
        persist()
    }

    func remove(at offsets: IndexSet) {
        links.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @StateObject private var inbox = Inbox()
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                composer
                linkList
            }
            .background(Color(red: 0.05, green: 0.09, blue: 0.14))
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Naru")
                .font(.system(size: 44, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
            Text("나루 — where your streams arrive")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.45, green: 0.72, blue: 0.75))
            Text("See the hidden patterns in everything you've saved.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Paste a link…", text: $draft)
                .focused($fieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.done)
                .onSubmit(save)
                .padding(12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)

            Button(action: save) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(red: 0.45, green: 0.72, blue: 0.75))
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var linkList: some View {
        Group {
            if inbox.links.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "water.waves")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Nothing has arrived yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(inbox.links) { link in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(link.url)
                                .font(.callout)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(link.savedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete { inbox.remove(at: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func save() {
        inbox.add(draft)
        draft = ""
        fieldFocused = false
    }
}

#Preview {
    ContentView()
}
