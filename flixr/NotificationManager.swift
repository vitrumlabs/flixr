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
    private(set) var pendingMovieID: Int? = nil

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Always attempt to save the token when auth state is known.
        // On re-launches the FCM token is cached so this succeeds without
        // waiting for the APNs round-trip.
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self, let uid = user?.uid else { return }
            Task { await self.fetchAndSaveToken(for: uid) }
        }
    }

    // Called by AppDelegate after Messaging.messaging().apnsToken is set.
    // Handles first-ever token generation where the cached token isn't
    // available yet when the auth listener fires.
    func apnsTokenDidArrive() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { await fetchAndSaveToken(for: uid) }
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

    func consumePendingMovieID() {
        pendingMovieID = nil
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        if let idStr = info["movieId"] as? String, let id = Int(idStr), id > 0 {
            pendingMovieID = id
        }
        completionHandler()
    }
}

extension NotificationManager: MessagingDelegate {
    // Fired when the token refreshes — save the new token immediately
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await self.db.collection("users").document(uid).setData(["fcmToken": token], merge: true) }
    }
}
