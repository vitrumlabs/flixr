import SwiftUI

struct DoneScreen: View {
    var go: (LoginScreen) -> Void
    var userName: String = ""

    private var firstName: String {
        userName.components(separatedBy: " ").first.map { $0.isEmpty ? "" : $0 } ?? ""
    }

    var body: some View {
        ScreenShell(dim: 0.5) {
            VStack(spacing: 0) {
                Spacer()

                // Success badge
                ZStack {
                    Circle()
                        .fill(Color.flxRed.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.flxRed.opacity(0.35), radius: 30)
                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.flxRed)
                }
                .padding(.bottom, 12)

                // Headline
                VStack(spacing: 0) {
                    Text(firstName.isEmpty ? "You're in!" : "You're in,")
                        .font(.flxDisplay(48))
                        .tracking(-1.2)
                        .foregroundColor(.white)
                    if !firstName.isEmpty {
                        Text("\(firstName).")
                            .font(.flxDisplay(48))
                            .tracking(-1.2)
                            .foregroundColor(.flxRed)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

                Text("Your feed is ready.\nTime to find your next favorite.")
                    .font(.system(size: 17))
                    .foregroundColor(.fg2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.bottom, 32)

                Spacer()

                FlxButton(title: "Dive In", variant: .primary, icon: "arrow.right") { go(.welcome) }
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
