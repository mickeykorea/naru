import SwiftUI

struct ContentView: View {
    @StateObject private var store = ArchiveStore()
    @State private var selectedTab: String? = nil
    @State private var showSaveSheet = false
    @State private var selectedItem: SavedItem? = nil
    @State private var toast: String? = nil
    @Namespace private var tabIndicator

    private var shown: [SavedItem] {
        guard let tab = selectedTab else { return store.items }
        return store.items.filter { $0.category == tab }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if !store.items.isEmpty { tabs }
                    if store.items.isEmpty {
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
        .sheet(isPresented: $showSaveSheet) {
            SaveSheet(existingCategories: store.categories, onSave: save)
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item)
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-detail") {
                selectedItem = store.items.first
            }
            #endif
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Naru")
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
            Text("\(store.items.count) saved")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Color(.systemGray))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: store.items.count)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                tabItem(nil, label: "All", count: store.items.count)
                ForEach(store.categories, id: \.self) { cat in
                    tabItem(cat, label: cat, count: store.items.filter { $0.category == cat }.count)
                }
            }
            // the indicator slide is the only animated part of a tab switch;
            // grid content swaps instantly (filtering is replacement, not movement)
            .animation(.snappy(duration: 0.25, extraBounce: 0), value: selectedTab)
        }
        .padding(.bottom, 18)
    }

    private func tabItem(_ value: String?, label: String, count: Int) -> some View {
        Button {
            selectedTab = value
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Text(label).font(.subheadline.weight(selectedTab == value ? .semibold : .regular))
                    Text("\(count)").font(.caption2).foregroundStyle(Color(.systemGray))
                }
                .foregroundStyle(selectedTab == value ? .primary : Color(.systemGray))
                ZStack {
                    Rectangle().fill(.clear).frame(height: 2)
                    if selectedTab == value {
                        Rectangle()
                            .fill(Color.primary)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "tabline", in: tabIndicator)
                    }
                }
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  alignment: .leading, spacing: 24) {
            ForEach(shown) { item in
                Button { selectedItem = item } label: {
                    SaveTile(item: item)
                }
                .buttonStyle(PressableStyle())
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation(.easeOut(duration: 0.25)) { store.remove(item) }
                    } label: { Label("Remove", systemImage: "trash") }
                }
            }
        }
        // new identity per tab: kills cross-tab move-diffing, so switching
        // categories swaps content instantly instead of sliding cards around.
        // Save/remove still animate via withAnimation at their call sites.
        .id(selectedTab)
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
        Button { showSaveSheet = true } label: {
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

    private func save(_ item: SavedItem, thumbnail: UIImage?) {
        if let thumbnail, let data = thumbnail.jpegData(compressionQuality: 0.8) {
            try? data.write(to: ArchiveStore.thumbnailURL(for: item.id))
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeOut(duration: 0.3)) { store.add(item) }
        showSaveSheet = false
        withAnimation(.easeOut(duration: 0.25)) { toast = "Saved to \(item.category)" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeIn(duration: 0.25)) { toast = nil }
        }
    }
}

#Preview {
    ContentView()
}
