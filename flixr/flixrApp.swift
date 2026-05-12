import SwiftUI
import FirebaseCore
import GoogleSignIn
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {}

@main
struct flixrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    @State private var library: UserLibrary

    init() {
        FirebaseApp.configure()
        MobileAds.shared.start()
        _authManager = State(initialValue: AuthManager())
        _library = State(initialValue: UserLibrary())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(library)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
