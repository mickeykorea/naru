import SwiftUI

struct ContentView: View {
    @StateObject private var store = ArchiveStore()
    @State private var selectedTab: String? = nil
    @State private var showSaveSheet = false
    @State private var showSearch = false
    @State private var selectedItem: SavedItem? = nil
    @State private var toast: String? = nil
    @State private var bottomBarHidden = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollRun: CGFloat = 0
    @State private var pushEdge: Edge = .trailing
    @Environment(\.scenePhase) private var scenePhase

    private var shown: [SavedItem] {
        guard let tab = selectedTab else { return store.items }
        return store.items.filter { $0.category == tab }
    }

    private var tabOrder: [String?] {
        [nil] + store.categories.map { Optional($0) }
    }

    private func swipeToAdjacentCategory(_ dx: CGFloat) {
        guard !store.items.isEmpty,
              let index = tabOrder.firstIndex(of: selectedTab) else { return }
        let next = dx < 0 ? index + 1 : index - 1
        guard tabOrder.indices.contains(next) else { return }
        pushEdge = dx < 0 ? .trailing : .leading
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            selectedTab = tabOrder[next]
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if !store.items.isEmpty {
                            tabs
                            grid
                        }
                    }
                    // without this, an empty archive's narrow content gets
                    // centered by the ScrollView and reads as a left indent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    // clear the floating glass button row, with air below it
                    .padding(.top, 76)
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
                        bottomBarHidden = false
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
                        bottomBarHidden = true
                    } else if scrollRun < -12 {
                        bottomBarHidden = false
                    }
                }
                // horizontal-dominant swipes page between categories;
                // vertical scrolling keeps priority (simultaneous, high bar)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25)
                        .onEnded { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }
                            swipeToAdjacentCategory(dx)
                        }
                )
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
            bottomBar
            if let toast { toastView(toast) }
        }
        .overlay(alignment: .top) { statusBarFrost }
        .overlay(alignment: .topTrailing) { moreButton }
        #if DEBUG
        .overlay {
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-type") {
                typeSpecimen
            }
        }
        #endif
        .background(backgroundWash)
        .sheet(isPresented: $showSaveSheet) {
            SaveSheet(existingCategories: store.categories, onSave: save)
        }
        .sheet(isPresented: $showSearch) {
            SearchSheet(items: store.items) { id, note in store.setNote(note, for: id) }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item) { store.setNote($0, for: item.id) }
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
                Task { await store.upgradeSummaries() }
            }
        }
        .task { await store.upgradeSummaries() }
    }

    #if DEBUG
    private var typeSpecimen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach([("semibold", Font.Weight.semibold), ("bold", .bold),
                         ("heavy", .heavy), ("black", .black)], id: \.0) { name, weight in
                    ForEach([-0.5, 0.0, 0.5], id: \.self) { tracking in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Naru")
                                .font(.system(size: 24, weight: weight))
                                .tracking(tracking)
                            Text("\(name) · tracking \(tracking, specifier: "%.1f")")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 70)
        }
        .background(Color(.systemBackground))
    }
    #endif

    // light-gray wash, breathing slightly brighter at the top (Clock ref);
    // darkened from near-white so the white masonry cards read as surfaces
    @Environment(\.colorScheme) private var colorScheme
    private var backgroundWash: LinearGradient {
        let colors = colorScheme == .dark
            ? [Color(white: 0.05), Color(white: 0)]
            : [Color(white: 0.97), Color(white: 0.93)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    private var moreButton: some View {
        Menu {
            Button("Nothing here yet", action: {}).disabled(true)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .tint(.primary)
        .glassEffect(.regular.interactive(), in: Circle())
        .padding(.trailing, 20)
        .padding(.top, 8)
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
        .padding(.bottom, 28)
    }

    // BeReal tabs: no underline — selection is weight + color
    private func tabItem(_ value: String?, label: String, count: Int) -> some View {
        Button {
            selectedTab = value
        } label: {
            HStack(spacing: 5) {
                Text(label).font(.system(size: 15, weight: selectedTab == value ? .semibold : .regular))
                Text("\(count)").font(.system(size: 11)).foregroundStyle(Color(.systemGray))
            }
            .foregroundStyle(selectedTab == value ? .primary : Color(.systemGray))
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    // every third thumbnail save renders full-bleed (Notes-ref rhythm);
    // position within the shown list keeps the rule deterministic
    private var styledEntries: [(item: SavedItem, style: SaveCard.Style)] {
        var thumbCount = 0
        return shown.map { item in
            guard SaveCard.hasLoadableThumbnail(item) else { return (item, .text) }
            thumbCount += 1
            return (item, thumbCount % 3 == 0 ? .fullBleed : .inset)
        }
    }

    private var grid: some View {
        MasonryGrid(entries: styledEntries) { item, style, position in
            Button { selectedItem = item } label: {
                SaveCard(item: item, style: style,
                         cropNudge: SaveCard.cropNudges[position % 3])
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
        // new identity per tab: kills cross-tab move-diffing, so switching
        // categories swaps content instantly instead of sliding cards around.
        // Save/remove still animate via withAnimation at their call sites.
        // Tab taps stay instant (no withAnimation); swipes animate this
        // transition as a directional push.
        .id(selectedTab)
        .transition(.push(from: pushEdge))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Nothing saved yet.")
                .font(.system(size: 20, weight: .semibold))
            Text("Share anything to Naru from any app,\nor paste a link below.")
                .font(.system(size: 15))
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

    // Notes-ref corner chrome: search bottom-left, save bottom-right
    private var bottomBar: some View {
        GlassEffectContainer {
            HStack {
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                }
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityIdentifier("search-button")
                Spacer()
                Button { showSaveSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(width: 52, height: 52)
                }
                .glassEffect(.regular.tint(.primary.opacity(0.92)).interactive(), in: Circle())
            }
            .tint(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .offset(y: bottomBarHidden ? 140 : 0)
        .animation(.snappy(duration: 0.3, extraBounce: 0), value: bottomBarHidden)
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
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
