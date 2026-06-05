import SwiftUI
import Combine

// MARK: - Color tokens

extension Color {
    static let flxRed      = Color(hex: "E50914")
    static let flxRedHi    = Color(hex: "FF3340")
    static let flxRedDeep  = Color(hex: "B00710")
    static let fg2         = Color.white.opacity(0.78)
    static let fg3         = Color.white.opacity(0.55)
    static let fg4         = Color.white.opacity(0.30)
    static let borderSubtle = Color.white.opacity(0.08)
    static let borderMedium = Color.white.opacity(0.16)

    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch s.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Font helpers (Barlow via condensed SF Pro, Manrope via default SF Pro)

extension Font {
    static func flxDisplay(_ size: CGFloat, weight: Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}

// MARK: - Poster plate background

struct PosterPlate: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("FlixrBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geo.size.height)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .opacity(0.85)
                    .saturation(1.05)
                    .clipped()
                // Black-to-clear gradient (design: left 22%→50%→78%)
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.22),
                        .init(color: .black.opacity(0.55), location: 0.5),
                        .init(color: .clear, location: 0.78)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                // Radial vignette
                RadialGradient(
                    colors: [.clear, .black.opacity(0.45)],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.height * 0.55
                )
            }
        }
    }
}

// MARK: - Screen shell

struct ScreenShell<Content: View>: View {
    var backdrop = true
    var dim: Double = 0.6
    var midDim: Double? = nil  // mid-gradient opacity; defaults to 0.86 for other screens
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if backdrop { PosterPlate().ignoresSafeArea() }
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(dim), location: 0),
                    .init(color: .black.opacity(midDim ?? 0.86), location: 0.6),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            content()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - FlxButton

struct FlxButton: View {
    enum Variant { case primary, secondary, ghost, apple, google }

    var title: String
    var variant: Variant = .primary
    var icon: String? = nil
    var isDisabled = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLeading { leadingIcon }
                Text(title).lineLimit(1)
                if !isLeading, let sf = icon {
                    Image(systemName: sf).font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .padding(.horizontal, 22)
        }
        .buttonStyle(FlxButtonStyle(variant: variant, isDisabled: isDisabled))
        .disabled(isDisabled)
    }

    private var isLeading: Bool { variant == .apple || variant == .google }

    @ViewBuilder private var leadingIcon: some View {
        if variant == .google {
            GoogleGIcon().frame(width: 20, height: 20)
        } else if let sf = icon {
            Image(systemName: sf)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 20, height: 20)
        }
    }
}

private struct FlxButtonStyle: ButtonStyle {
    var variant: FlxButton.Variant
    var isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let p = configuration.isPressed
        return configuration.label
            .font(.system(size: 16, weight: .semibold))
            .tracking(-0.08)
            .foregroundStyle(fgColor)
            .background(bgFor(p))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(borderColor, lineWidth: borderW))
            .scaleEffect(p ? 0.98 : 1)
            .opacity(isDisabled ? 0.5 : 1)
            .animation(.easeOut(duration: 0.14), value: p)
    }

    @ViewBuilder func bgFor(_ pressed: Bool) -> some View {
        switch variant {
        case .primary:
            LinearGradient(
                colors: pressed
                    ? [Color(hex: "D6070F"), Color(hex: "B8060D")]
                    : [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                startPoint: .top, endPoint: .bottom
            )
        case .secondary: Color.white.opacity(pressed ? 0.14 : 0.08)
        case .ghost:     Color.clear
        case .apple:     Color(white: pressed ? 0.10 : 0.043)
        case .google:    Color(white: pressed ? 0.929 : 1.0)
        }
    }

    var fgColor:     Color { variant == .google ? Color(white: 0.043) : .white }
    var borderColor: Color {
        switch variant {
        case .primary:            .black.opacity(0.28)
        case .secondary, .apple:  .white.opacity(0.16)
        default:                  .clear
        }
    }
    var borderW: CGFloat { (variant == .ghost || variant == .google) ? 0 : 1 }
}

// MARK: - Google "G" icon (official asset from GoogleSignIn SDK)

struct GoogleGIcon: View {
    var body: some View {
        Image("GoogleG")
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Pill text field

struct FlxInput: View {
    var icon: String? = nil
    var isSecure = false
    var placeholder = ""
    @Binding var text: String
    var error: String? = nil
    var keyboardType: UIKeyboardType = .default
    var trailing: AnyView? = nil

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(focused ? .flxRed : .fg3)
                        .frame(width: 18, height: 18)
                        .animation(.easeOut(duration: 0.2), value: focused)
                }
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .textContentType(.oneTimeCode)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($focused)
                .tint(.flxRed)

                if let t = trailing { t }
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(Color.white.opacity(0.04))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    error != nil
                        ? Color.flxRed.opacity(0.55)
                        : (focused ? Color.flxRed.opacity(0.55) : .borderSubtle),
                    lineWidth: 1
                )
            )
            .shadow(color: focused ? Color.flxRed.opacity(0.15) : .clear, radius: 4)
            .animation(.easeOut(duration: 0.2), value: focused)

            if let error {
                HStack(spacing: 6) {
                    Circle().fill(Color.flxRedHi).frame(width: 6, height: 6)
                    Text(error).font(.system(size: 13)).foregroundColor(.flxRedHi)
                }
                .padding(.leading, 18)
            }
        }
    }
}

// MARK: - Logo

struct FlxLogo: View {
    var size: CGFloat = 28
    var body: some View {
        Image("FlixrLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size * 1.25)
    }
}

// MARK: - Liquid glass back button

struct LiquidGlassButton<Label: View>: View {
    var size: CGFloat = 40
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundColor(.white)
                .frame(width: size, height: size)
        }
        .glassEffect(in: Circle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - "or" divider

struct OrDivider: View {
    var body: some View {
        HStack(spacing: 14) {
            Rectangle().fill(Color.borderSubtle).frame(height: 1)
            Text("OR")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(.fg3)
            Rectangle().fill(Color.borderSubtle).frame(height: 1)
        }
    }
}

// MARK: - Animated loading dots

struct LoadingDots: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .opacity(i == phase ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}

// MARK: - Banner (error / warning toast)

struct FlxBanner: View {
    enum Tone { case error, warning }
    var tone: Tone = .error
    var title = ""
    var message = ""
    var icon: String? = nil

    private var accent: Color {
        tone == .error ? .flxRedHi : Color(red: 1, green: 0.706, blue: 0.235)
    }
    private var bg: Color {
        tone == .error
            ? Color.flxRed.opacity(0.1)
            : Color(red: 1, green: 0.706, blue: 0.235).opacity(0.1)
    }
    private var border: Color {
        tone == .error
            ? Color.flxRed.opacity(0.35)
            : Color(red: 1, green: 0.706, blue: 0.235).opacity(0.30)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon ?? (tone == .error ? "lock.circle" : "exclamationmark.triangle"))
                .foregroundColor(accent)
                .font(.system(size: 16))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.fg2)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(bg)
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Display H1 (two-line with optional red accent line)

struct DisplayH1: View {
    var line1: String
    var accentLine: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(line1).foregroundColor(.white)
            if let accent = accentLine {
                Text(accent).foregroundColor(.flxRed)
            }
        }
        .font(.flxDisplay(44))
        .tracking(-1.1)
    }
}

// MARK: - Arc spinner

struct FlxSpinner: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 3)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.flxRed, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(rotation - 90))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
