import SwiftUI

struct ErrorScreen: View {
    enum Kind { case network, server }

    var go: (LoginScreen) -> Void
    var kind: Kind

    private var config: (icon: String, accent: Color, title: String, sub: String, cta: String) {
        switch kind {
        case .network:
            return (
                icon: "wifi.slash",
                accent: Color(red: 1, green: 0.706, blue: 0.235),
                title: "No connection.",
                sub: "We can't reach Flixr right now. Check your Wi-Fi or cellular signal and try again.",
                cta: "Try Again"
            )
        case .server:
            return (
                icon: "exclamationmark.circle",
                accent: .flxRed,
                title: "Something broke.",
                sub: "Our projector hit a snag. We're on it — try again in a moment.",
                cta: "Retry"
            )
        }
    }

    var body: some View {
        ScreenShell(dim: 0.7) {
            VStack(alignment: .leading, spacing: 0) {
                LiquidGlassButton(action: { go(.signin) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                }

                Spacer(minLength: 0)

                // Icon
                ZStack {
                    Circle()
                        .fill(config.accent.opacity(0.12))
                        .frame(width: 96, height: 96)
                        .shadow(color: config.accent.opacity(0.25), radius: 30)
                    Image(systemName: config.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(config.accent)
                }
                .padding(.bottom, 24)

                Text(config.title)
                    .font(.flxDisplay(44))
                    .tracking(-1.1)
                    .foregroundColor(.white)

                Text(config.sub)
                    .font(.system(size: 16))
                    .foregroundColor(.fg2)
                    .lineSpacing(2)
                    .padding(.top, 14)
                    .padding(.bottom, 28)

                FlxButton(title: config.cta, variant: .primary, icon: "arrow.right") { go(.signin) }

                Button("Cancel") { go(.welcome) }
                    .font(.system(size: 14))
                    .foregroundColor(.fg3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
