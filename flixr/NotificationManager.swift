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
    private var authListener: AuthStateDidChangeListenerHandle?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Fetch and save the FCM token whenever a user signs in
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let uid = user?.uid else { return }
            Task { await self?.fetchAndSaveToken(for: uid) }
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

    func fetchAndSaveToken(for uid: String) async {
        do {
            let token = try await Messaging.messaging().token()
            try? await db.collection("users").document(uid).setData(["fcmToken": token], merge: true)
        } catch {
            print("[FCM] Token fetch failed: \(error.localizedDescription)")
        }
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
        Task { try? await self.db.collection("users").document(uid).setData(["fcmToken": token], merge: true) }
    }
}
