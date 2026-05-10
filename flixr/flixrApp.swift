import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {}

@main
struct flixrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
