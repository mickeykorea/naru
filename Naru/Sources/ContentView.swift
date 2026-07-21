import SwiftUI

struct ContentView: View {
    @StateObject private var store = ArchiveStore()
    @State private var selectedTab: String? = nil
    @State private var showSaveSheet = false
    @State private var showSearch = false
    @State private var showSettings = false
    @AppStorage(Appearance.storageKey) private var appearanceRaw = Appearance.system.rawValue
    @State private var selectedItem: SavedItem? = nil
    @State private var toast: String? = nil
    @State private var bottomBarHidden = false
    // reference box: these mutate on every scroll tick, and as @State they
    // invalidated the whole body (masonry included) once per frame
    private final class ScrollTracker {
        var lastOffset: CGFloat = 0
        var run: CGFloat = 0
    }
    @State private var scrollTracker = ScrollTracker()
    @State private var pushEdge: Edge = .trailing
    // a horizontal page-swipe never scrolls, so it doesn't cancel tile
    // buttons the way vertical scrolling does — veto their taps instead
    @State private var suppressTileTaps = false
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
                    let delta = offset - scrollTracker.lastOffset
                    scrollTracker.lastOffset = offset
                    if offset <= minOffset + 8 {
                        if bottomBarHidden { bottomBarHidden = false }
                        scrollTracker.run = 0
                        return
                    }
                    // rubber-band zones produce phantom direction reversals
                    if offset >= maxOffset - 1 { return }
                    // accumulate displacement in the current direction so slow
                    // scrolls still trigger; reset on direction change
                    if (delta >= 0) != (scrollTracker.run >= 0) { scrollTracker.run = 0 }
                    scrollTracker.run += delta
                    if scrollTracker.run > 12 {
                        if !bottomBarHidden { bottomBarHidden = true }
                    } else if scrollTracker.run < -12 {
                        if bottomBarHidden { bottomBarHidden = false }
                    }
                }
                // horizontal-dominant swipes page between categories;
                // vertical scrolling keeps priority (simultaneous, high bar)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25)
                        .onChanged { value in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                suppressTileTaps = true
                            }
                        }
                        .onEnded { value in
                            // the tile's touch-up lands around the same
                            // moment as this — lift the veto a beat later
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                suppressTileTaps = false
                            }
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
            SearchSheet(items: store.items,
                        onNoteChange: { store.setNote($1, for: $0) },
                        onCategoryChange: { store.setCategory($1, for: $0) })
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item,
                            categories: store.categories,
                            onNoteChange: { store.setNote($0, for: item.id) },
                            onCategoryChange: { store.setCategory($0, for: item.id) })
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-detail") {
                selectedItem = store.items.first
            }
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-detail-long"),
               var demo = store.items.first {
                demo.summary = String(
                    repeating: "Public libraries quietly became the last noncommercial "
                        + "indoor spaces in American life, and their budgets keep shrinking anyway. ",
                    count: 6)
                selectedItem = demo
            }
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-toast") {
                toast = "Saved to Reading"
            }
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-settings") {
                showSettings = true
            }
            // present settings, then flip the stored appearance while it is
            // open — reproduces the live theme-switch path for verification
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-theme-flip") {
                appearanceRaw = Appearance.dark.rawValue   // known start
                showSettings = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    appearanceRaw = Appearance.light.rawValue
                }
            }
            // reproduces the "System" label clipping: switch the picker to
            // the longest label while the sheet is presented
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-theme-system") {
                appearanceRaw = Appearance.dark.rawValue
                showSettings = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    appearanceRaw = Appearance.system.rawValue
                }
            }
            if ProcessInfo.processInfo.arguments.contains("-naru-demo-share") {
                // purge earlier runs' apple.com saves so the share test's
                // post-share assertion can only match THIS run's item
                store.mutate { $0.removeAll { $0.domain.contains("apple.com") } }
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
                applyAppearanceOverride()
                withAnimation(.easeOut(duration: 0.3)) { store.reload() }
                Task { await store.upgradeSummaries() }
            }
        }
        .task { await store.upgradeSummaries() }
        // theme override rides on the window, not .preferredColorScheme:
        // a presented sheet doesn't re-inherit the presenter's scheme live,
        // and preferredColorScheme(nil) won't revert an already-overridden
        // sheet back to the device. The window trait cascades to every
        // presentation and .unspecified restores System cleanly.
        .onAppear { applyAppearanceOverride() }
        .onChange(of: appearanceRaw) { applyAppearanceOverride() }
    }

    private func applyAppearanceOverride() {
        let style: UIUserInterfaceStyle
        switch Appearance(rawValue: appearanceRaw) ?? .system {
        case .system: style = .unspecified
        case .light:  style = .light
        case .dark:   style = .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.windows.forEach {
                $0.overrideUserInterfaceStyle = style
            }
        }
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
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
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
        .accessibilityIdentifier("more-button")
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
            Button {
                guard !suppressTileTaps else { return }
                selectedItem = item
            } label: {
                SaveCard(item: item, style: style,
                         cropNudge: SaveCard.cropNudge(at: position))
            }
            .buttonStyle(PressableStyle())
            .id(item.id)
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
            .contextMenu {
                let others = store.categories.filter { $0 != item.category }
                if !others.isEmpty {
                    Menu {
                        ForEach(others, id: \.self) { cat in
                            Button(cat) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    store.setCategory(cat, for: item.id)
                                }
                            }
                        }
                    } label: { Label("Move to", systemImage: "folder") }
                }
                Button(role: .destructive) {
                    SaveCard.invalidateAspect(for: item.id)
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

    // toast glass blends with the wash instead of contrasting —
    // near-white translucent in light mode, dark grey in dark mode
    private var toastTint: Color {
        colorScheme == .dark
            ? Color(white: 0.16).opacity(0.9)
            : Color.white.opacity(0.45)
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
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(toastTint))
            .padding(.bottom, 92)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func save(_ item: SavedItem, thumbnail: UIImage?) {
        if let thumbnail, let data = thumbnail.jpegData(compressionQuality: 0.8) {
            try? data.write(to: ArchiveStore.thumbnailURL(for: item.id))
            SaveCard.invalidateAspect(for: item.id)
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
