import SwiftUI

struct VerifyEmailScreen: View {
    var go: (LoginScreen) -> Void
    var userEmail: String = ""
    var hasError   = false
    var isVerified = false

    @Environment(AuthManager.self) private var auth
    @State private var countdown = 30
    @State private var isChecking = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScreenShell(dim: 0.7) {
            VStack(alignment: .leading, spacing: 0) {
                if !isVerified {
                    LiquidGlassButton(action: { go(.signup) }) {
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
                        Text("You're all set\(userEmail.isEmpty ? "." : ", **\(userEmail)**.")")
                    } else {
                        Text("We sent a verification link\(userEmail.isEmpty ? "." : " to **\(userEmail)**.")  Click it, then come back here.")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.fg2)
                .lineSpacing(2)
                .tint(.white)
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
                    FlxButton(title: "Continue", variant: .primary, icon: "arrow.right") { go(.done) }
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
