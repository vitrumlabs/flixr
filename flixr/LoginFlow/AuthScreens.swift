import SwiftUI
import SafariServices

// MARK: - Sign In

enum SignInError { case wrongPassword, locked }

struct SignInScreen: View {
    var go: (LoginScreen) -> Void
    var error: SignInError? = nil
    var initialEmail: String = ""
    var onSubmit: (String, String) -> Void = { _, _ in }

    @State private var email: String
    @State private var password = ""
    @State private var showPassword = false
    @State private var activeLegal: LegalDestination? = nil

    init(
        go: @escaping (LoginScreen) -> Void,
        error: SignInError? = nil,
        initialEmail: String = "",
        onSubmit: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.go = go
        self.error = error
        self.onSubmit = onSubmit
        _email = State(initialValue: initialEmail)
    }

    private var isLocked: Bool { error == .locked }
    private var isWrong:  Bool { error == .wrongPassword }

    var body: some View {
        ScreenShell(dim: 0.7) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LiquidGlassButton(action: { go(.welcome) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Spacer().frame(height: 52)
                    DisplayH1(line1: "Welcome", accentLine: "back.")

                    Text("Pick up where you left off.")
                        .font(.system(size: 16))
                        .foregroundColor(.fg2)
                        .padding(.top, 14)
                        .padding(.bottom, 28)

                    if isLocked {
                        FlxBanner(
                            tone: .error,
                            title: "Account temporarily locked",
                            message: "Too many attempts. Try again in 15 minutes, or reset your password.",
                            icon: "lock.circle"
                        )
                        .padding(.bottom, 16)
                    }

                    // Social auth
                    SocialAuthButtons(go: go)

                    OrDivider().padding(.vertical, 20)

                    VStack(spacing: 10) {
                        FlxInput(icon: "envelope", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                        FlxInput(
                            icon: "lock",
                            isSecure: !showPassword,
                            placeholder: "Password",
                            text: $password,
                            error: isWrong ? "Incorrect password. Try again or reset it below." : nil,
                            trailing: AnyView(
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 18))
                                        .foregroundColor(.fg3)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            )
                        )
                    }

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            onSubmit(email, password)
                            go(.forgot)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.fg2)
                        .frame(minHeight: 44)
                    }
                    .padding(.top, 10)

                    Spacer().frame(height: 22)

                    FlxButton(title: "Sign In", variant: .primary, icon: "arrow.right", isDisabled: isLocked) {
                        onSubmit(email, password)
                        go(.signinLoading)
                    }

                    Spacer().frame(height: 32)
                    LegalConsentFooter(activeLegal: $activeLegal)
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .sheet(item: $activeLegal) { dest in
                SafariView(url: dest.url)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Sign Up

enum SignUpError { case emailExists }

struct SignUpScreen: View {
    var go: (LoginScreen) -> Void
    var error: SignUpError? = nil
    var initialEmail: String = ""
    var initialName: String = ""
    var onSubmit: (String, String, String) -> Void = { _, _, _ in }

    @State private var name: String
    @State private var email: String
    @State private var password = ""
    @State private var showPassword = false
    @State private var activeLegal: LegalDestination? = nil

    init(
        go: @escaping (LoginScreen) -> Void,
        error: SignUpError? = nil,
        initialEmail: String = "",
        initialName: String = "",
        onSubmit: @escaping (String, String, String) -> Void = { _, _, _ in }
    ) {
        self.go = go
        self.error = error
        self.onSubmit = onSubmit
        _name  = State(initialValue: initialName)
        _email = State(initialValue: initialEmail)
    }

    private var emailExists: Bool { error == .emailExists }

    var body: some View {
        ScreenShell(dim: 0.7) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LiquidGlassButton(action: { go(.welcome) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Spacer().frame(height: 12)
                    DisplayH1(line1: "Start your", accentLine: "journey.")

                    Text("Join millions of movie lovers.")
                        .font(.system(size: 16))
                        .foregroundColor(.fg2)
                        .padding(.top, 16)
                        .padding(.bottom, 32)

                    if emailExists {
                        VStack(alignment: .leading, spacing: 8) {
                            FlxBanner(
                                tone: .warning,
                                title: "Email already in use",
                                message: "That email is on a Flixr account.",
                                icon: "exclamationmark.triangle"
                            )
                            Button("Sign in instead?") { go(.signin) }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .underline()
                                .frame(minHeight: 44)
                                .padding(.leading, 14)
                        }
                        .padding(.bottom, 24)
                    }

                    // Social auth
                    SocialAuthButtons(go: go)

                    OrDivider().padding(.vertical, 28)

                    VStack(spacing: 12) {
                        FlxInput(icon: "person", placeholder: "Your name", text: $name)
                        FlxInput(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            error: emailExists ? "This email is already registered." : nil,
                            keyboardType: .emailAddress
                        )
                        FlxInput(
                            icon: "lock",
                            isSecure: !showPassword,
                            placeholder: "Password (8+ chars)",
                            text: $password,
                            trailing: AnyView(
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 18))
                                        .foregroundColor(.fg3)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            )
                        )
                    }

                    Spacer().frame(height: 32)

                    FlxButton(title: "Create Account", variant: .primary, icon: "arrow.right") {
                        onSubmit(email, name, password)
                        go(emailExists ? .signup : .signupLoading)
                    }

                    Spacer().frame(height: 32)
                    LegalConsentFooter(activeLegal: $activeLegal)
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .sheet(item: $activeLegal) { dest in
                SafariView(url: dest.url)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Shared social auth buttons

struct SocialAuthButtons: View {
    var go: (LoginScreen) -> Void
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack(spacing: 10) {
            if let error = auth.authError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.flxRed)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
            }
            FlxButton(
                title: "Continue with Apple",
                variant: .apple,
                icon: "apple.logo",
                isDisabled: auth.isLoading
            ) {
                Task {
                    await auth.signInWithApple()
                    if auth.user != nil { go(.mainApp) }
                }
            }
            FlxButton(
                title: "Continue with Google",
                variant: .google,
                isDisabled: auth.isLoading
            ) {
                Task {
                    await auth.signInWithGoogle()
                    if auth.user != nil { go(.mainApp) }
                }
            }
        }
    }
}

// MARK: - Legal consent footer

struct LegalConsentFooter: View {
    @Binding var activeLegal: LegalDestination?

    var body: some View {
        HStack(spacing: 0) {
            Text("By continuing, you agree to our ")
                .foregroundColor(.fg3)
            Button("Terms of Use") { activeLegal = .terms }
                .foregroundColor(.fg2)
                .underline()
            Text(" and ")
                .foregroundColor(.fg3)
            Button("Privacy Policy") { activeLegal = .privacy }
                .foregroundColor(.fg2)
                .underline()
        }
        .font(.system(size: 12))
        .buttonStyle(.plain)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
