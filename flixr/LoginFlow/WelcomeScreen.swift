import SwiftUI

struct WelcomeScreen: View {
    var go: (LoginScreen) -> Void

    var body: some View {
        ScreenShell(dim: 0.3, midDim: 0.55) {
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 0) {
                    // Top bar
                    HStack {
                        FlxLogo(size: 34)
                        Spacer()
                        Button("Sign In") { go(.signin) }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 11)
                            .padding(.horizontal, 26)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.black.opacity(0.28), lineWidth: 1))
                    }
                    .padding(.bottom, 28)

                    // Hero headline
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Find movies")
                            .font(.flxDisplay(54))
                            .tracking(-1.5)
                            .foregroundColor(.white)
                        Text("you'll love.")
                            .font(.flxDisplay(54))
                            .tracking(-1.5)
                            .foregroundColor(.flxRed)
                    }
                    .padding(.bottom, 14)

                    Text("Swipe, discover, and build your perfect watchlist.")
                        .font(.system(size: 18))
                        .foregroundColor(.fg2)
                        .lineSpacing(3)
                        .frame(maxWidth: geo.size.width * 0.62, alignment: .leading)
                        .padding(.bottom, 24)

                    // Get Started — left-aligned pill
                    Button(action: { go(.signup) }) {
                        HStack(spacing: 16) {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                                .tracking(-0.1)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(width: geo.size.width * 0.55)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.28), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                    .padding(.bottom, 28)

                    Spacer(minLength: 36)

                    // Feature badges row with vertical dividers
                    HStack(alignment: .top, spacing: 0) {
                        FeatureBadge(icon: "heart.fill",    title: "Personalized",  caption: "Recommendations\njust for you.")
                        Color.white.opacity(0.18).frame(width: 1, height: 96)
                        FeatureBadge(icon: "bolt.fill",     title: "Quick & Easy",  caption: "Swipe to find your\nnext favorite.")
                        Color.white.opacity(0.18).frame(width: 1, height: 96)
                        FeatureBadge(icon: "bookmark.fill", title: "Your Watchlist", caption: "Save and organize\nwhat you love.")
                    }

                    Spacer(minLength: 8)

                    // Footer: text blends into popcorn via multi-stop gradient overlay
                    ZStack(alignment: .bottomLeading) {
                        Image("FlixrPopcorn")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, -22)
                            .overlay(
                                LinearGradient(
                                    stops: [
                                        .init(color: .black.opacity(0.92), location: 0),
                                        .init(color: .black.opacity(0.75), location: 0.30),
                                        .init(color: .black.opacity(0.30), location: 0.60),
                                        .init(color: .clear,               location: 0.85),
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ready to dive in?")
                                .font(.flxDisplay(24))
                                .foregroundColor(.white)
                            Text("Join millions of movie lovers\nand start your journey today.")
                                .font(.system(size: 14))
                                .foregroundColor(.fg3)
                                .lineSpacing(2)
                        }
                        // Wider container so text visually merges with popcorn scene
                        .frame(maxWidth: 230, alignment: .leading)
                        // Fade the right edge of the text block into the popcorn
                        .mask(
                            LinearGradient(
                                colors: [.white, .white, .clear],
                                startPoint: .leading,
                                endPoint: UnitPoint(x: 0.85, y: 0)
                            )
                        )
                        .padding(.bottom, geo.safeAreaInsets.bottom + 110)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Feature badge

private struct FeatureBadge: View {
    var icon: String
    var title: String
    var caption: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Reddish haze background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.flxRed.opacity(0.32), Color.flxRed.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 28
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(Circle().strokeBorder(Color.flxRed.opacity(0.22), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.flxRed)
            }
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.system(size: 12))
                .foregroundColor(.fg3)
                .multilineTextAlignment(.center)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}
