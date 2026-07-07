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

    var category: String {
        let d = domain
        if d.contains("spotify") || d.contains("music") || d.contains("soundcloud") { return "Sounds" }
        if d.contains("youtube") || d.contains("vimeo") || d.contains("netflix") { return "Watch" }
        if d.contains("pinterest") || d.contains("instagram") || d.contains("mobbin") { return "Visual" }
        return "Reads"
    }

    var title: String {
        guard let u = URL(string: url.hasPrefix("http") ? url : "https://" + url) else { return url }
        let path = u.path.split(separator: "/").last.map(String.init) ?? ""
        let cleaned = path.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        return cleaned.count > 3 ? cleaned.prefix(1).capitalized + cleaned.dropFirst() : domain
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

    func remove(_ link: SavedLink) {
        links.removeAll { $0.id == link.id }
        persist()
    }

    var categories: [String] {
        var seen = [String]()
        for l in links where !seen.contains(l.category) { seen.append(l.category) }
        return seen
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(links) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ContentView: View {
    @StateObject private var inbox = Inbox()
    @State private var selectedTab: String? = nil
    @State private var showComposer = false
    @State private var toast: String? = nil

    private var shown: [SavedLink] {
        guard let tab = selectedTab else { return inbox.links }
        return inbox.links.filter { $0.category == tab }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if !inbox.links.isEmpty { tabs }
                    if inbox.links.isEmpty {
                        emptyState
                    } else {
                        grid
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            saveButton
            if let toast { toastView(toast) }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showComposer) { ComposerSheet(onSave: save) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("나루")
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
            Text("\(inbox.links.count) saved")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Color(.systemGray))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: inbox.links.count)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                tabItem(nil, label: "All", count: inbox.links.count)
                ForEach(inbox.categories, id: \.self) { cat in
                    tabItem(cat, label: cat, count: inbox.links.filter { $0.category == cat }.count)
                }
            }
        }
        .padding(.bottom, 18)
    }

    private func tabItem(_ value: String?, label: String, count: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedTab = value }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Text(label).font(.subheadline.weight(selectedTab == value ? .semibold : .regular))
                    Text("\(count)").font(.caption2).foregroundStyle(Color(.systemGray))
                }
                .foregroundStyle(selectedTab == value ? .primary : Color(.systemGray))
                Rectangle()
                    .fill(selectedTab == value ? Color.primary : .clear)
                    .frame(height: 2)
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  alignment: .leading, spacing: 24) {
            ForEach(shown) { link in
                SaveTile(link: link)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation(.easeOut(duration: 0.25)) { inbox.remove(link) }
                        } label: { Label("Remove", systemImage: "trash") }
                    }
            }
        }
        .animation(.easeOut(duration: 0.3), value: shown)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing saved yet.")
                .font(.title3.weight(.semibold))
            Text("Share anything to Naru from any app,\nor paste a link below.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray))
        }
        .padding(.top, 60)
    }

    private var saveButton: some View {
        Button { showComposer = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Save a link")
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .background(Color.primary, in: Capsule())
        }
        .padding(.bottom, 24)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.primary, in: Capsule())
            .padding(.bottom, 92)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func save(_ url: String) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeOut(duration: 0.3)) { inbox.add(url) }
        showComposer = false
        withAnimation(.easeOut(duration: 0.25)) { toast = "Saved" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeIn(duration: 0.25)) { toast = nil }
        }
    }
}

struct SaveTile: View {
    let link: SavedLink

    private var hue: Double {
        Double(abs(link.domain.hashValue) % 360) / 360.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemGray6))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    VStack(alignment: .leading, spacing: 6) {
                        Text(link.title)
                            .font(.subheadline.weight(.medium))
                            .fontDesign(.serif)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: iconName)
                            .font(.body)
                            .foregroundStyle(Color(.systemGray))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(link.domain) · \(link.savedAt.formatted(.relative(presentation: .numeric)))")
                    .font(.footnote)
                    .foregroundStyle(Color(.systemGray))
                    .lineLimit(1)
            }
        }
    }

    private var iconName: String {
        switch link.category {
        case "Sounds": "waveform"
        case "Watch": "play.circle"
        case "Visual": "photo"
        default: "text.alignleft"
        }
    }
}

struct ComposerSheet: View {
    let onSave: (String) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Save a link")
                .font(.title3.weight(.semibold))
                .padding(.top, 24)
            TextField("Paste a link…", text: $draft)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
            Button(action: submit) {
                Text("Save")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.primary, in: Capsule())
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(240)])
        .presentationCornerRadius(24)
        .onAppear { focused = true }
    }

    private func submit() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
    }
}

#Preview {
    ContentView()
}
