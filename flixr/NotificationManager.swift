import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Observation
import UIKit
import UserNotifications

@Observable
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private(set) var systemGranted: Bool = false

    private let db = Firestore.firestore()
    private var cachedToken: String?
    private var authListener: AuthStateDidChangeListenerHandle?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Flush the cached token whenever a user signs in
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self, let uid = user?.uid, let token = self.cachedToken else { return }
            self.saveToken(token, for: uid)
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            systemGranted = settings.authorizationStatus == .authorized
        }
    }

    func requestPermission() async {
        guard let granted = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        else { return }
        await MainActor.run { systemGranted = granted }
        if granted {
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    func saveToken(_ token: String, for uid: String) {
        db.collection("users").document(uid).setData(["fcmToken": token], merge: true)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        cachedToken = token
        // Save immediately if user is already signed in, otherwise the
        // auth state listener above will flush it once sign-in completes
        if let uid = Auth.auth().currentUser?.uid {
            saveToken(token, for: uid)
        }
    }
}
