import SwiftUI

struct ForgotScreen: View {
    var go: (LoginScreen) -> Void
    var isSent = false
    var userEmail: String = ""

    @State private var email: String

    init(go: @escaping (LoginScreen) -> Void, isSent: Bool = false, userEmail: String = "") {
        self.go = go
        self.isSent = isSent
        self.userEmail = userEmail
        _email = State(initialValue: userEmail)
    }

    var body: some View {
        ScreenShell(dim: 0.7) {
            VStack(alignment: .leading, spacing: 0) {
                if !isSent {
                    LiquidGlassButton(action: { go(.signin) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                Spacer(minLength: 0)

                if !isSent {
                    DisplayH1(line1: "Forgot your", accentLine: "password?")

                    Text("No worries — we'll send a reset link to your email.")
                        .font(.system(size: 16))
                        .foregroundColor(.fg2)
                        .lineSpacing(2)
                        .padding(.top, 14)
                        .padding(.bottom, 24)

                    FlxInput(icon: "envelope", placeholder: "Email", text: $email, keyboardType: .emailAddress)

                    Spacer().frame(height: 18)

                    FlxButton(title: "Send Reset Link", variant: .primary, icon: "arrow.right") {
                        go(.forgotLoading)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.flxRed.opacity(0.12))
                            .frame(width: 84, height: 84)
                            .shadow(color: Color.flxRed.opacity(0.25), radius: 30)
                        Image(systemName: "envelope")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.flxRed)
                    }
                    .padding(.bottom, 8)

                    DisplayH1(line1: "Check your", accentLine: "inbox.")

                    Group {
                        if email.isEmpty {
                            Text("A reset link is on its way. It'll expire in 30 minutes.")
                        } else {
                            Text("A reset link is on its way to **\(email)**. It'll expire in 30 minutes.")
                        }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.fg2)
                    .lineSpacing(2)
                    .padding(.top, 14)
                    .padding(.bottom, 24)

                    FlxButton(title: "Back to Sign In", variant: .secondary) { go(.signin) }

                    HStack(spacing: 4) {
                        Text("Didn't get it?").foregroundColor(.fg3)
                        Button("Resend") { }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .underline()
                    }
                    .font(.system(size: 14))
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
