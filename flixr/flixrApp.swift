import SwiftUI
import FirebaseCore

@main
struct flixrApp: App {
    @State private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}
