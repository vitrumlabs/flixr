import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import GoogleSignIn
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {}

@main
struct flixrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    @State private var library: UserLibrary

    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        #endif
        FirebaseApp.configure()
        MobileAds.shared.start()
        _authManager = State(initialValue: AuthManager())
        _library = State(initialValue: UserLibrary())
        Task { await RemoteConfigManager.shared.fetchAndActivate() }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(library)
                .environment(RemoteConfigManager.shared)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
