import SwiftUI

@main
struct NaruApp: App {
    init() {
        Typeface.register()
        #if DEBUG
        // seeded before the first ArchiveStore reads; lives here because
        // the share extension compiles Models.swift but not the seeder
        if let seedID = ArchiveStore.uiTestSeedID {
            ArchiveStore.seedIfNeeded(seedID)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
