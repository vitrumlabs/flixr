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

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
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
        guard let token = fcmToken,
              let uid = Auth.auth().currentUser?.uid else { return }
        saveToken(token, for: uid)
    }
}
