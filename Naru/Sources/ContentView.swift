import SwiftUI

struct ContentView: View {
    @StateObject private var store = ArchiveStore()
    @State private var selectedTab: String? = nil
    @State private var showSaveSheet = false
    @State private var selectedItem: SavedItem? = nil
    @State private var toast: String? = nil
    @State private var saveButtonHidden = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollRun: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase

    private var shown: [SavedItem] {
        guard let tab = selectedTab else { return store.items }
        return store.items.filter { $0.category == tab }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        if !store.items.isEmpty {
                            tabs
                            grid
                        }
                    }
                    // without this, an empty archive's narrow content gets
                    // centered by the ScrollView and reads as a left indent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .onScrollGeometryChange(
                    for: CGRect.self,
                    // offset is inset-relative: rest position is -contentInsets.top,
                    // bottom limit is contentSize - container + contentInsets.bottom
                    of: { CGRect(x: $0.contentOffset.y,
                                 y: -$0.contentInsets.top,
                                 width: $0.contentSize.height - $0.containerSize.height
                                        + $0.contentInsets.bottom,
                                 height: 0) }
                ) { _, value in
                    let offset = value.origin.x
                    let minOffset = value.origin.y
                    let maxOffset = value.size.width
                    let delta = offset - lastScrollOffset
                    lastScrollOffset = offset
                    if offset <= minOffset + 8 {
                        saveButtonHidden = false
                        scrollRun = 0
                        return
                    }
                    // rubber-band zones produce phantom direction reversals
                    if offset >= maxOffset - 1 { return }
                    // accumulate displacement in the current direction so slow
                    // scrolls still trigger; reset on direction change
                    if (delta >= 0) != (scrollRun >= 0) { scrollRun = 0 }
                    scrollRun += delta
                    if scrollRun > 12 {
                        saveButtonHidden = true
                    } else if scrollRun < -12 {
                        saveButtonHidden = false
                    }
                }
                .onAppear {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-naru-demo-scroll"),
                       let last = store.items.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                    #endif
                }
            }
            if store.items.isEmpty { emptyState }
            saveButton
            if let toast { toastView(toast) }
        }
        .overlay(alignment: .top) { statusBarFrost }
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
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-share") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let activity = UIActivityViewController(
                        activityItems: [URL(string: "https://www.apple.com")!],
                        applicationActivities: nil)
                    UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                        .first?.rootViewController?
                        .present(activity, animated: true)
                }
            }
            #endif
        }
        // pick up items saved through the share extension while away
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                withAnimation(.easeOut(duration: 0.3)) { store.reload() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Naru.")
                .font(.inter(24, .heavy))
            Text("\(store.items.count) saved")
                .font(.inter(13))
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
            .animation(.snappy(duration: 0.25, extraBounce: 0), value: selectedTab)
        }
        .padding(.bottom, 18)
    }

    // BeReal tabs: no underline — selection is weight + color
    private func tabItem(_ value: String?, label: String, count: Int) -> some View {
        Button {
            selectedTab = value
        } label: {
            HStack(spacing: 5) {
                Text(label).font(.inter(15, selectedTab == value ? .semibold : .regular))
                Text("\(count)").font(.inter(11)).foregroundStyle(Color(.systemGray))
            }
            .foregroundStyle(selectedTab == value ? .primary : Color(.systemGray))
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
                .id(item.id)
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
        VStack(spacing: 8) {
            Text("Nothing saved yet.")
                .font(.inter(20, .semibold))
            Text("Share anything to Naru from any app,\nor paste a link below.")
                .font(.inter(15))
                .foregroundStyle(Color(.systemGray))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // scrollEdgeEffectStyle only frosts system bars; Naru has no nav bar,
    // so the status-bar frost is drawn manually: material masked to
    // dissolve downward, invisible until content scrolls beneath it
    private var statusBarFrost: some View {
        VariableBlurView(maxBlurRadius: 9)
            .frame(height: 82)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    private var saveButton: some View {
        Button { showSaveSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Save a link")
            }
            .font(.inter(17, .semibold))
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
        }
        .glassEffect(.regular.tint(.primary.opacity(0.92)).interactive())
        .padding(.bottom, 24)
        .offset(y: saveButtonHidden ? 130 : 0)
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: saveButtonHidden)
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.inter(13, .medium))
            .foregroundStyle(Color(.systemBackground))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(.primary.opacity(0.92)))
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
