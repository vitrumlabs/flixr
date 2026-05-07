import SwiftUI
import Combine

struct VerifyEmailScreen: View {
    var go: (LoginScreen) -> Void
    var userEmail: String = ""
    var hasError  = false
    var isVerified = false

    // OTP state — single string, displayed in 6 boxes
    @State private var code = ""
    @State private var countdown = 28
    @FocusState private var inputFocused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var filled: Bool { code.count == 6 }

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

                // Icon
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

                Text(isVerified
                     ? "You're all set\(userEmail.isEmpty ? "." : ", **\(userEmail)**.")"
                     : "We sent a 6-digit code\(userEmail.isEmpty ? "." : " to **\(userEmail)**.")")
                    .font(.system(size: 16))
                    .foregroundColor(.fg2)
                    .lineSpacing(2)
                    .tint(.white)
                    .padding(.top, 14)
                    .padding(.bottom, 24)

                if hasError {
                    FlxBanner(
                        tone: .error,
                        title: "That code didn't match",
                        message: "Double-check the email — codes expire after 10 minutes."
                    )
                    .padding(.bottom, 16)
                }

                if !isVerified {
                    // OTP boxes with hidden single TextField
                    OTPBoxes(code: $code, hasError: hasError, focused: $inputFocused)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 16)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { inputFocused = true } }

                    FlxButton(title: "Verify Email", variant: .primary, icon: "arrow.right", isDisabled: !filled) {
                        go(hasError ? .verify : .verifyOk)
                    }

                    HStack(spacing: 4) {
                        Text("Didn't get it?").foregroundColor(.fg3)
                        if countdown > 0 {
                            Text("Resend in \(countdown)s").foregroundColor(.fg2)
                        } else {
                            Button("Resend code") { countdown = 28 }
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

// MARK: - OTP box row

private struct OTPBoxes: View {
    @Binding var code: String
    var hasError: Bool
    var focused: FocusState<Bool>.Binding

    var body: some View {
        ZStack {
            // Hidden text field to capture input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused(focused)
                .onChange(of: code) { _, v in
                    let digits = v.filter { $0.isNumber }
                    code = String(digits.prefix(6))
                }
                .opacity(0)
                .frame(width: 1, height: 1)

            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    OTPDigitBox(
                        digit: digit(at: i),
                        isActive: focused.wrappedValue && i == min(code.count, 5),
                        hasError: hasError
                    )
                    .onTapGesture { focused.wrappedValue = true }
                }
            }
        }
    }

    private func digit(at i: Int) -> String {
        guard i < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: i)])
    }
}

private struct OTPDigitBox: View {
    var digit: String
    var isActive: Bool
    var hasError: Bool

    private var borderColor: Color {
        if hasError { return Color.flxRed.opacity(0.55) }
        return digit.isEmpty ? (isActive ? Color.flxRed.opacity(0.45) : .borderSubtle) : Color.flxRed.opacity(0.45)
    }

    var body: some View {
        Text(digit.isEmpty ? " " : digit)
            .font(.flxDisplay(22))
            .foregroundColor(.white)
            .frame(width: 36, height: 48)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .shadow(color: isActive ? Color.flxRed.opacity(0.1) : .clear, radius: 4)
    }
}
