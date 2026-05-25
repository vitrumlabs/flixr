import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Observation
import UIKit
import UserNotifications

private let fcmTokenField = "fcmToken"

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
            let ref = db.collection("users").document(uid)
            // onUserSignUp (Cloud Function) creates the doc asynchronously after sign-in.
            // Use updateData — allowed by rules — and retry with backoff until doc exists.
            for attempt in 0..<6 {
                do {
                    try await ref.updateData([fcmTokenField: token])
                    return
                } catch let err as NSError
                    where err.domain == FirestoreErrorDomain
                    && err.code == FirestoreErrorCode.Code.notFound.rawValue {
                    guard attempt < 5 else { break }
                    let delay = UInt64(pow(2.0, Double(attempt))) * 500_000_000
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
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
        Task { await self.fetchAndSaveToken(for: uid) }
    }
}
