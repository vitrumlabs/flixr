import SwiftUI
import Combine

struct VerifyEmailScreen: View {
    var go: (LoginScreen) -> Void
    var userEmail: String = ""
    var hasError   = false
    var isVerified = false

    @Environment(AuthManager.self) private var auth
    @State private var countdown = 30
    @State private var isChecking = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func boldEmail(before: String, after: String) -> AttributedString {
        var result = AttributedString(before)
        var bold = AttributedString(userEmail)
        bold.swiftUI.font = .system(size: 16, weight: .bold)
        result += bold
        result += AttributedString(after)
        return result
    }

    var body: some View {
        ScreenShell(dim: 0.7) {
            VStack(alignment: .leading, spacing: 0) {
                if !isVerified {
                    LiquidGlassButton(action: { go(.welcome) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(Color.flxRed.opacity(0.12))
                        .frame(width: 76, height: 76)
                        .shadow(color: Color.flxRed.opacity(0.25), radius: 30)
                    Image(systemName: isVerified ? "checkmark" : "envelope")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.flxRed)
                }

                Spacer().frame(height: 20)

                DisplayH1(
                    line1: isVerified ? "Email" : "Check your",
                    accentLine: isVerified ? "verified." : "inbox."
                )

                Group {
                    if isVerified {
                        if userEmail.isEmpty {
                            Text("You're all set.")
                        } else {
                            Text(boldEmail(before: "You're all set, ", after: "."))
                        }
                    } else {
                        if userEmail.isEmpty {
                            Text("We sent a verification link. Click it, then come back here.")
                        } else {
                            Text(boldEmail(before: "We sent a verification link to ", after: ". Click it, then come back here."))
                        }
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.fg2)
                .lineSpacing(2)
                .padding(.top, 14)
                .padding(.bottom, 24)

                if hasError {
                    FlxBanner(
                        tone: .error,
                        title: "Not verified yet",
                        message: "Click the link in your email, then tap the button below."
                    )
                    .padding(.bottom, 16)
                }

                if !isVerified {
                    FlxButton(
                        title: "I've verified my email",
                        variant: .primary,
                        icon: "arrow.right",
                        isDisabled: isChecking
                    ) {
                        isChecking = true
                        Task {
                            let verified = await auth.checkEmailVerified()
                            isChecking = false
                            go(verified ? .verifyOk : .verifyError)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Didn't get it?").foregroundColor(.fg3)
                        if countdown > 0 {
                            Text("Resend in \(countdown)s").foregroundColor(.fg2)
                        } else {
                            Button("Resend link") {
                                Task { await auth.resendVerificationEmail() }
                                countdown = 30
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .underline()
                        }
                    }
                    .font(.system(size: 14))
                    .padding(.top, 18)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onReceive(timer) { _ in if countdown > 0 { countdown -= 1 } }
                }

                if isVerified {
                    FlxButton(title: "Let's go", variant: .primary, icon: "arrow.right") { go(.mainApp) }
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
