import SwiftUI

// MARK: - Generic loading screen (used standalone in artboard view)

struct LoadingView: View {
    enum Brand { case flixr, apple }
    var title: String
    var sub: String
    var brand: Brand = .flixr

    var body: some View {
        ScreenShell(dim: 0.6) {
            VStack(spacing: 28) {
                Spacer()

                // Brand mark
                switch brand {
                case .apple:
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.043))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.borderMedium, lineWidth: 1))
                            .frame(width: 72, height: 72)
                        Image(systemName: "apple.logo")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                case .flixr:
                    FlxLogo(size: 36)
                }

                FlxSpinner()

                VStack(spacing: 6) {
                    Text(title)
                        .font(.flxDisplay(28))
                        .tracking(-0.7)
                        .foregroundColor(.white)
                    Text(sub)
                        .font(.system(size: 15))
                        .foregroundColor(.fg2)
                }
                .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Auto-advancing wrapper (used by router for transitional loading states)

struct AutoAdvanceLoadingView: View {
    var title: String
    var sub: String
    var next: LoginScreen
    var go: (LoginScreen) -> Void
    var brand: LoadingView.Brand = .flixr
    var delay: Double = 1.8

    var body: some View {
        LoadingView(title: title, sub: sub, brand: brand)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                go(next)
            }
    }
}
