import SwiftUI

struct SavedLink: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    let savedAt: Date

    var domain: String {
        guard let host = URL(string: url.hasPrefix("http") ? url : "https://" + url)?.host else {
            return "link"
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
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

enum Theme {
    static let night = Color(red: 0.04, green: 0.07, blue: 0.12)
    static let card = Color.white.opacity(0.06)
    static let teal = Color(red: 0.45, green: 0.72, blue: 0.75)
    static let moon = Color(red: 0.93, green: 0.95, blue: 0.93)
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
            .background(Theme.night)
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("Naru")
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.moon)
            Text("나루 — where your streams arrive")
                .font(.footnote)
                .foregroundStyle(Theme.teal)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Paste a link…", text: $draft)
                    .focused($fieldFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(fieldFocused ? Theme.teal.opacity(0.6) : .clear, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.18), value: fieldFocused)

            Button(action: save) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSave ? Theme.teal : Color.white.opacity(0.15))
            }
            .disabled(!canSave)
            .animation(.easeOut(duration: 0.15), value: canSave)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var linkList: some View {
        Group {
            if inbox.links.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(inbox.links) { link in
                        LinkCard(link: link)
                            .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity))
                    }
                    .onDelete { inbox.remove(at: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .animation(.spring(duration: 0.45, bounce: 0.25), value: inbox.links)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "water.waves")
                .font(.system(size: 34))
                .foregroundStyle(Theme.teal.opacity(0.5))
            Text("Nothing has arrived yet")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Paste a link above to start your stream.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func save() {
        guard canSave else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
            inbox.add(draft)
        }
        draft = ""
        fieldFocused = false
    }
}

struct LinkCard: View {
    let link: SavedLink

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(link.domain)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.teal.opacity(0.12), in: Capsule())
                Spacer()
                Text(link.savedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(link.url)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
