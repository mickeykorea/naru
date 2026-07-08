import SwiftUI

@main
struct NaruApp: App {
    init() {
        Typeface.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
