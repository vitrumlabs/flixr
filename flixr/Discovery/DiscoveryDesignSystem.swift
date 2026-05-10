import SwiftUI

// MARK: - Tokens

extension Color {
    static let dLine = Color.white.opacity(0.10)
    static let dFg2  = Color.white.opacity(0.78)
    static let dFg3  = Color.white.opacity(0.55)
}

// MARK: - Procedural cinematic backdrop (16:9 by default)

struct BackdropArt: View {
    var movie: Movie
    var aspectRatio: CGFloat = 16 / 9

    var body: some View {
        let p = movie.palette
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [p.a, p.b], startPoint: .topLeading, endPoint: .bottomTrailing)

                // Accent haze top-left
                RadialGradient(
                    colors: [p.accent.opacity(0.33), .clear],
                    center: UnitPoint(x: 0.18, y: 0.22),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )
                // Glow haze bottom-right
                RadialGradient(
                    colors: [p.glow.opacity(0.13), .clear],
                    center: UnitPoint(x: 0.92, y: 0.7),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.7
                )
                // Orb
                RadialGradient(
                    colors: [p.glow.opacity(0.8), p.accent.opacity(0.33), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.17
                )
                .frame(width: geo.size.width * 0.34, height: geo.size.width * 0.34)
                .clipShape(Circle())
                .blur(radius: 2)
                .position(x: geo.size.width * 0.79, y: geo.size.height * 0.34)

                // Horizon line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, p.glow.opacity(0.5), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .opacity(0.6)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.58)

                // Bottom fade
                LinearGradient(colors: [.clear, p.b.opacity(0.8), p.b], startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Procedural poster (2:3)

struct PosterArt: View {
    var movie: Movie
    var width: CGFloat = 80

    var body: some View {
        let p = movie.palette
        let lines = movie.title.uppercased().split(separator: " ").map(String.init)
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [p.a, p.b], startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(
                colors: [p.glow.opacity(0.4), .clear],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 0, endRadius: width * 0.4
            )
            RadialGradient(
                colors: [p.accent.opacity(0.33), .clear],
                center: UnitPoint(x: 0.5, y: 0.78),
                startRadius: 0, endRadius: width * 0.25
            )

            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: width * 0.11, weight: .heavy, design: .default).width(.condensed))
                        .tracking(0.04 * width * 0.11)
                        .foregroundColor(.white.opacity(0.85))
                        .blendMode(.screen)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 12, y: 5)
    }
}

// MARK: - Top app bar (logo + filter button with badge)

struct DiscoveryTopBar: View {
    var onFilter: () -> Void

    var body: some View {
        HStack {
            FlxLogo(size: 36)
            Spacer()
            Button(action: onFilter) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(in: Circle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

// MARK: - Action buttons (Skip / Like / Info)

struct ActionButton: View {
    enum Kind { case skip, like }

    var kind: Kind
    var size: CGFloat = 72
    var action: (() -> Void)? = nil

    private var color: Color {
        kind == .skip ? .flxRed : Color(hex: "2BD17E")
    }
    private var borderColor: Color {
        kind == .skip ? Color.flxRed.opacity(0.65) : Color(hex: "2BD17E").opacity(0.65)
    }
    private var glowColor: Color {
        kind == .skip ? Color.flxRed.opacity(0.35) : Color(hex: "2BD17E").opacity(0.35)
    }

    var body: some View {
        Button(action: { action?() }) {
            Group {
                if kind == .skip {
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.32, weight: .bold))
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: size * 0.33))
                }
            }
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(
                RadialGradient(
                    colors: [Color(hex: "1c1c1e").opacity(0.95), Color(hex: "0a0a0c").opacity(0.95)],
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: size * 0.5
                )
            )
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(borderColor, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.55), radius: 11, y: 4)
            .shadow(color: glowColor, radius: 13)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.94))
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    var label: String
    var isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? .white : Color.dFg2)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(isActive ? Color.flxRed.opacity(0.16) : Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isActive ? Color.flxRed.opacity(0.55) : Color.dLine,
                        lineWidth: 1
                    )
                )
        }
    }
}

// MARK: - Custom tab bar (Discover+Watchlist pill · Profile circle)

enum DiscoverTab: Equatable { case discover, watchlist, profile }

struct DiscoveryTabBar: View {
    var active: DiscoverTab
    var onChange: (DiscoverTab) -> Void

    var body: some View {
        HStack {
            // Discover + Watchlist pill
            HStack(spacing: 0) {
                tabItem("movieclapper", "Discover", .discover)
                tabItem("bookmark",        "Watchlist", .watchlist)
            }
            .glassEffect(in: Capsule())

            Spacer()

            // Profile circle — pushed to far right
            Button(action: { onChange(.profile) }) {
                Image(systemName: active == .profile ? "person.fill" : "person")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.dFg2)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(in: Circle())
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func tabItem(_ icon: String, _ label: String, _ tab: DiscoverTab) -> some View {
        let isActive = active == tab
        let filledIcon: String = switch tab {
            case .watchlist: "bookmark.fill"
            case .discover:  "movieclapper"
            case .profile:   icon
        }
        Button(action: { onChange(tab) }) {
            VStack(spacing: 3) {
                Image(systemName: isActive ? filledIcon : icon)
                    .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .flxRed : Color.dFg2)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive ? .flxRed : Color.dFg2)
            }
            .frame(height: 52)
            .padding(.horizontal, 24)
        }
    }
}
