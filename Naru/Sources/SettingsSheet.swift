import SwiftUI

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static let storageKey = "naru.appearance"
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Appearance.storageKey) private var appearanceRaw = Appearance.system.rawValue

    // TODO: swap for the App Store link once Naru is published
    private let shareURL = URL(string: "https://github.com/mickeykorea/naru")!
    private let shareMessage = "Naru — a beautiful personal archive. Save anything, keep it beautifully."
    private let siteURL = URL(string: "https://mickeyoh.com")!

    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    section("Appearance") {
                        SettingsGroup {
                            pickerRow(icon: "circle.lefthalf.filled.inverse", title: "Theme",
                                      selection: appearance)
                        }
                        caption("Naru follows your device by default.")
                    }

                    // footer sits under the About group at the same gap the
                    // Theme card keeps from its caption above (section spacing)
                    VStack(alignment: .leading, spacing: 10) {
                        SettingsGroup {
                            NavigationLink {
                                AboutView()
                            } label: {
                                SettingsRow(icon: "info.circle.fill", title: "About") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(.systemGray3))
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 4) {
                            Text("Designed & built by")
                                .foregroundStyle(Color(.systemGray))
                            Link("mickeyoh.com", destination: siteURL)
                                .foregroundStyle(Color(.systemGray))
                                .fontWeight(.semibold)
                                .accessibilityIdentifier("site-link")
                        }
                        .font(.system(size: 13))
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color.settingsSheet)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                    }
                    .tint(.primary)
                    .glassEffect(.regular.interactive(), in: Circle())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareURL, message: Text(shareMessage)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 30, height: 30)
                    }
                    .tint(.primary)
                    .glassEffect(.regular.interactive(), in: Circle())
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
        .presentationBackground(Color.settingsSheet)
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private func section(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.systemGray))
                .padding(.horizontal, 24)
            content()
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color(.systemGray))
            .padding(.horizontal, 24)
    }

    private func pickerRow(icon: String, title: String, selection: Binding<Appearance>) -> some View {
        SettingsRow(icon: icon, title: title) {
            Menu {
                Picker("", selection: selection) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selection.wrappedValue.label)
                        .font(.system(size: 16))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(.systemGray))
            }
            .tint(.primary)
        }
    }
}

// grouped rounded surface holding one or more rows, dividers auto-inserted
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.settingsCard, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(name: icon)
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }
}

// plain SF Symbol glyph, no chip — flat monochrome gray like the reference
struct SettingsIcon: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 20))
            // monochrome (not hierarchical) so every glyph fills with the
            // exact same systemGray — no per-layer opacity variation
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(Color(.systemGray))
            .frame(width: 28, height: 28)
    }
}

extension Color {
    // card matches the content tiles outside (SaveTile uses systemGray6);
    // pinned to systemGray6's own values so sheet "elevated" appearance
    // can't drift it lighter. The sheet background goes darker instead, so
    // the cards still separate in dark mode.
    static let settingsSheet = Color(UIColor { tc in
        // sits between the dimmed home behind (~0.04) and the cards (0.11)
        // so the sheet's edge reads against the home, cards still float
        tc.userInterfaceStyle == .dark ? UIColor(white: 0.075, alpha: 1) : .systemBackground
    })
    static let settingsCard = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1)  // = systemGray6 dark
            : UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1)  // = systemGray6 light
    })
}

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Naru")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.top, 48)

                Text("Version \(version)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(.systemGray))

                Text("Naru (나루) is the Korean word for a small river ferry landing — the place things arrive.")
                    .font(.garamond(18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.settingsSheet)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
