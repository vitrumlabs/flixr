import SwiftUI

enum LoginScreen: Hashable {
    case welcome
    case signin, signinError, signinLocked, signinLoading
    case signup, signupExists, signupLoading
    case verify, verifyError, verifyOk
    case forgot, forgotLoading, forgotSent
    case swipe, swipeLoading
    case done
    case networkError, serverError
    case mainApp
}

struct LoginFlowView: View {
    var onComplete: (() -> Void)? = nil
    @Environment(AuthManager.self) private var auth
    @State private var screen: LoginScreen = .welcome
    @State private var currentEmail    = ""
    @State private var currentName     = ""
    @State private var currentPassword = ""

    var body: some View {
        ZStack {
            screenView(for: screen)
                .id(screen)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.22), value: screen)
    }

    @ViewBuilder
    private func screenView(for s: LoginScreen) -> some View {
        switch s {
        case .welcome:
            WelcomeScreen(go: go)

        case .signin:
            SignInScreen(
                go: go,
                initialEmail: currentEmail,
                onSubmit: { email, password in currentEmail = email; currentPassword = password }
            )
        case .signinError:
            SignInScreen(
                go: go,
                error: .wrongPassword,
                initialEmail: currentEmail,
                onSubmit: { email, password in currentEmail = email; currentPassword = password }
            )
        case .signinLocked:
            SignInScreen(
                go: go,
                error: .locked,
                initialEmail: currentEmail,
                onSubmit: { email, password in currentEmail = email; currentPassword = password }
            )
        case .signinLoading:
            AsyncLoadingView(title: "Signing you in", sub: "Just a moment…", go: go) {
                switch await auth.signIn(email: currentEmail, password: currentPassword) {
                case .success:         return .mainApp
                case .unverified:      return .verify
                case .wrongPassword:   return .signinError
                case .tooManyAttempts: return .signinLocked
                case .networkError:    return .networkError
                }
            }

        case .signup:
            SignUpScreen(
                go: go,
                onSubmit: { email, name, password in
                    currentEmail = email; currentName = name; currentPassword = password
                }
            )
        case .signupExists:
            SignUpScreen(
                go: go,
                error: .emailExists,
                initialEmail: currentEmail,
                initialName: currentName,
                onSubmit: { email, name, password in
                    currentEmail = email; currentName = name; currentPassword = password
                }
            )
        case .signupLoading:
            AsyncLoadingView(title: "Creating your account", sub: "Sending verification email…", go: go) {
                switch await auth.signUp(email: currentEmail, password: currentPassword, name: currentName) {
                case .success:     return .verify
                case .emailExists: return .signupExists
                case .networkError: return .networkError
                }
            }

        case .verify:
            VerifyEmailScreen(go: go, userEmail: currentEmail)
        case .verifyError:
            VerifyEmailScreen(go: go, userEmail: currentEmail, hasError: true)
        case .verifyOk:
            VerifyEmailScreen(go: go, userEmail: currentEmail, isVerified: true)

        case .forgot:
            ForgotScreen(go: go, userEmail: currentEmail, onSubmit: { email in currentEmail = email })
        case .forgotLoading:
            AsyncLoadingView(title: "Sending reset link", sub: "Hold tight…", go: go) {
                await auth.sendPasswordReset(email: currentEmail)
                return .forgotSent
            }
        case .forgotSent:
            ForgotScreen(go: go, isSent: true, userEmail: currentEmail)

        case .swipe:
            SwipeScreen(go: go)
        case .swipeLoading:
            AutoAdvanceLoadingView(title: "Tuning your feed", sub: "Cutting your trailer…", next: .done, go: go)

        case .done:
            DoneScreen(go: go, userName: currentName)

        case .networkError:
            ErrorScreen(go: go, kind: .network)
        case .serverError:
            ErrorScreen(go: go, kind: .server)

        case .mainApp:
            Color.clear.onAppear { onComplete?() }
        }
    }

    private func go(_ s: LoginScreen) {
        if s == .mainApp {
            onComplete?()
        } else {
            screen = s
        }
    }
}
