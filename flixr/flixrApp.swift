import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseAppCheck
import FirebaseMessaging
import GoogleSignIn
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = NotificationManager.shared
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        NotificationManager.shared.apnsTokenDidArrive()
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }
}

@main
struct flixrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authManager: AuthManager
    @State private var library: UserLibrary

    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity:  200 * 1024 * 1024,
            diskPath: "posterCache"
        )
        FirebaseApp.configure()
        if CommandLine.arguments.contains("UI_TESTING") {
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        }
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
                .environment(NotificationManager.shared)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
