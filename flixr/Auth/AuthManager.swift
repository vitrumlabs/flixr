import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

enum EmailSignInResult { case success, unverified, wrongPassword, tooManyAttempts, networkError }
enum EmailSignUpResult  { case success, emailExists, networkError }

@Observable
class AuthManager: NSObject {
    var user: FirebaseAuth.User? = nil
    var isReady = false
    var isLoading = false
    var isSigningOut = false
    var authError: String? = nil

    var uid: String? { user?.uid }

    private var currentNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    override init() {
        super.init()
        user = Auth.auth().currentUser?.isEmailVerified == true ? Auth.auth().currentUser : nil
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, u in
            self?.user = u?.isEmailVerified == true ? u : nil
            self?.isReady = true
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
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
            try await Auth.auth().signIn(with: credential)
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
            let rootVC = try await MainActor.run {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = scene.windows.first?.rootViewController
                else { throw AuthError.missingCredential }
                return rootVC
            }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingCredential
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async -> EmailSignInResult {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.isEmailVerified ? .success : .unverified
        } catch let error as NSError {
            let code = error.code
            if [AuthErrorCode.wrongPassword.rawValue,
                AuthErrorCode.invalidCredential.rawValue,
                AuthErrorCode.userNotFound.rawValue,
                AuthErrorCode.invalidEmail.rawValue].contains(code) { return .wrongPassword }
            if [AuthErrorCode.tooManyRequests.rawValue,
                AuthErrorCode.userDisabled.rawValue].contains(code) { return .tooManyAttempts }
            return .networkError
        }
    }

    func signUp(email: String, password: String, name: String) async -> EmailSignUpResult {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let req = result.user.createProfileChangeRequest()
            req.displayName = name
            try? await req.commitChanges()
            try? await result.user.sendEmailVerification()
            return .success
        } catch let error as NSError {
            return error.code == AuthErrorCode.emailAlreadyInUse.rawValue ? .emailExists : .networkError
        }
    }

    func sendPasswordReset(email: String) async {
        isLoading = true
        defer { isLoading = false }
        try? await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func resendVerificationEmail() async {
        try? await Auth.auth().currentUser?.sendEmailVerification()
    }

    func checkEmailVerified() async -> Bool {
        try? await Auth.auth().currentUser?.reload()
        return Auth.auth().currentUser?.isEmailVerified == true
    }

    func acceptCurrentUser() {
        user = Auth.auth().currentUser
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

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        do {
            try await currentUser.delete()
        } catch let error as NSError where error.code == AuthErrorCode.requiresRecentLogin.rawValue {
            try await reauthenticate(user: currentUser)
            try await currentUser.delete()
        }
        GIDSignIn.sharedInstance.signOut()
    }

    private func reauthenticate(user: FirebaseAuth.User) async throws {
        let providerIDs = user.providerData.map(\.providerID)

        if providerIDs.contains("google.com") {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleNotConfigured
            }
            let rootVC = try await MainActor.run {
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = scene.windows.first?.rootViewController
                else { throw AuthError.missingCredential }
                return rootVC
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingCredential
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await user.reauthenticate(with: credential)

        } else if providerIDs.contains("apple.com") {
            let nonce = randomNonce()
            currentNonce = nonce
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            let authorization = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<ASAuthorization, Error>) in
                let delegate = AppleSignInDelegate(continuation: continuation)
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else { throw AuthError.missingCredential }
            let credential = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            try await user.reauthenticate(with: credential)
        }
        // Email/password: no silent re-auth possible; caller surfaces the error
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
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) { return window }
        if let window = scenes.first?.windows.first { return window }
        guard let scene = scenes.first else { fatalError("No window scene available") }
        return UIWindow(windowScene: scene)
    }
}
