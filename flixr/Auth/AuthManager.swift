import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@Observable
class AuthManager: NSObject {
    var user: FirebaseAuth.User? = nil
    var isLoading = false
    var isSigningOut = false
    var authError: String? = nil

    private var currentNonce: String?

    override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        super.init()
        user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() async {
        isLoading = true
        authError = nil
        do {
            let nonce = randomNonce()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let result = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<ASAuthorization, Error>) in
                let delegate = AppleSignInDelegate(continuation: continuation)
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                // retain delegate for the lifetime of the request
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }

            guard
                let appleCredential = result.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else { throw AuthError.missingCredential }

            let credential = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            await createProfileIfNeeded(authResult.user, isNewUser: authResult.additionalUserInfo?.isNewUser == true)
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        authError = nil
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleNotConfigured
            }
            guard
                let scene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootVC = await scene.windows.first?.rootViewController
            else { throw AuthError.missingCredential }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingCredential
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            await createProfileIfNeeded(authResult.user, isNewUser: authResult.additionalUserInfo?.isNewUser == true)
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            isSigningOut = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            try? Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            isSigningOut = false
        }
    }

    // MARK: - Firestore Profile

    private func createProfileIfNeeded(_ user: FirebaseAuth.User, isNewUser: Bool) async {
        guard isNewUser else { return }
        let db = Firestore.firestore()
        try? await db.collection("users").document(user.uid).setData([
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "photoURL": user.photoURL?.absoluteString ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "watchlist": [],
            "liked": [],
            "skipped": [],
            "filters": ["genres": [], "decade": "", "minRating": 0],
        ])
    }
}

// MARK: - Errors

private enum AuthError: LocalizedError {
    case missingCredential
    case googleNotConfigured

    var errorDescription: String? {
        switch self {
        case .missingCredential: return "Authentication failed. Please try again."
        case .googleNotConfigured: return "Google Sign In is not configured yet."
        }
    }
}

// MARK: - Nonce helpers

private func randomNonce(length: Int = 32) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return bytes.map { String(format: "%02x", $0) }.joined()
}

private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

// MARK: - Apple Sign In delegate

private class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
