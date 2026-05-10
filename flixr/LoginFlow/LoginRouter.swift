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
    @State private var screen: LoginScreen = .welcome
    @State private var currentEmail  = ""
    @State private var currentName   = ""

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
                onSubmit: { email, _ in currentEmail = email }
            )
        case .signinError:
            SignInScreen(
                go: go,
                error: .wrongPassword,
                initialEmail: currentEmail,
                onSubmit: { email, _ in currentEmail = email }
            )
        case .signinLocked:
            SignInScreen(
                go: go,
                error: .locked,
                initialEmail: currentEmail,
                onSubmit: { email, _ in currentEmail = email }
            )
        case .signinLoading:
            AutoAdvanceLoadingView(title: "Signing you in", sub: "Just a moment…", next: .done, go: go)

        case .signup:
            SignUpScreen(
                go: go,
                onSubmit: { email, name in currentEmail = email; currentName = name }
            )
        case .signupExists:
            SignUpScreen(
                go: go,
                error: .emailExists,
                initialEmail: currentEmail,
                initialName: currentName,
                onSubmit: { email, name in currentEmail = email; currentName = name }
            )
        case .signupLoading:
            AutoAdvanceLoadingView(title: "Creating your account", sub: "Sending verification email…", next: .verify, go: go)

        case .verify:
            VerifyEmailScreen(go: go, userEmail: currentEmail)
        case .verifyError:
            VerifyEmailScreen(go: go, userEmail: currentEmail, hasError: true)
        case .verifyOk:
            VerifyEmailScreen(go: go, userEmail: currentEmail, isVerified: true)

        case .forgot:
            ForgotScreen(go: go, userEmail: currentEmail)
        case .forgotLoading:
            AutoAdvanceLoadingView(title: "Sending reset link", sub: "Hold tight…", next: .forgotSent, go: go)
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
