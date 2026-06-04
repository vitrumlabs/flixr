import SwiftUI

// MARK: - Tokens

extension Color {
    static let dLine = Color.white.opacity(0.10)
    static let dFg2  = Color.white.opacity(0.78)
    static let dFg3  = Color.white.opacity(0.55)
}

// MARK: - Cinematic backdrop — TMDB poster image with procedural fallback

struct BackdropArt: View {
    var movie: Movie
    var aspectRatio: CGFloat = 16 / 9

    private var imageURL: URL? {
        if let path = movie.backdropPath { return TMDBImage.backdropURL(path) }
        if let path = movie.posterPath   { return TMDBImage.posterURL(path, width: 500) }
        return nil
    }

    var body: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ProceduralBackdrop(palette: movie.palette, aspectRatio: aspectRatio)
                }
            }
            .id(url)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        } else {
            ProceduralBackdrop(palette: movie.palette, aspectRatio: aspectRatio)
        }
    }
}

private struct ProceduralBackdrop: View {
    var palette: MoviePalette
    var aspectRatio: CGFloat

    var body: some View {
        let p = palette
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [p.a, p.b], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [p.accent.opacity(0.33), .clear],
                               center: UnitPoint(x: 0.18, y: 0.22),
                               startRadius: 0, endRadius: geo.size.width * 0.6)
                RadialGradient(colors: [p.glow.opacity(0.13), .clear],
                               center: UnitPoint(x: 0.92, y: 0.7),
                               startRadius: 0, endRadius: geo.size.width * 0.7)
                RadialGradient(colors: [p.glow.opacity(0.8), p.accent.opacity(0.33), .clear],
                               center: .center, startRadius: 0, endRadius: geo.size.width * 0.17)
                    .frame(width: geo.size.width * 0.34, height: geo.size.width * 0.34)
                    .clipShape(Circle()).blur(radius: 2)
                    .position(x: geo.size.width * 0.79, y: geo.size.height * 0.34)
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, p.glow.opacity(0.5), .clear],
                                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1).opacity(0.6)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.58)
                LinearGradient(colors: [.clear, p.b.opacity(0.8), p.b], startPoint: .top, endPoint: .bottom)
                    .frame(height: geo.size.height * 0.4).frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Poster — TMDB image with procedural fallback

struct PosterArt: View {
    var movie: Movie
    var width: CGFloat = 80

    @State private var loadedImage: Image?
    @State private var loadingURL: URL?

    private var posterURL: URL? {
        guard let path = movie.posterPath else { return nil }
        return TMDBImage.posterURL(path, width: 342)
    }

    var body: some View {
        ZStack {
            if let image = loadedImage {
                image.resizable().scaledToFill()
            } else {
                ProceduralPoster(movie: movie, width: width)
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 12, y: 5)
        .task(id: posterURL) {
            guard let url = posterURL, url != loadingURL else { return }
            loadingURL = url
            loadedImage = nil
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let uiImage = UIImage(data: data) else { return }
            await MainActor.run { loadedImage = Image(uiImage: uiImage) }
        }
    }
}

private struct ProceduralPoster: View {
    var movie: Movie
    var width: CGFloat

    var body: some View {
        let p = movie.palette
        let lines = movie.title.uppercased().split(separator: " ").map(String.init)
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [p.a, p.b], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [p.glow.opacity(0.4), .clear],
                           center: UnitPoint(x: 0.5, y: 0.28), startRadius: 0, endRadius: width * 0.4)
            RadialGradient(colors: [p.accent.opacity(0.33), .clear],
                           center: UnitPoint(x: 0.5, y: 0.78), startRadius: 0, endRadius: width * 0.25)
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
            .padding(.horizontal, 8).padding(.bottom, 10)
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 12, y: 5)
    }
}

// MARK: - Top app bar (logo + search button)

struct DiscoveryTopBar: View {
    var onOpenProfile: () -> Void

    var body: some View {
        HStack {
            FlxLogo(size: 36)
            Spacer()
            Button(action: onOpenProfile) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Profile")
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
            .foregroundStyle(color)
            .frame(width: size, height: size)
        }
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(kind == .skip ? "Skip" : "Like")
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
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Tab identifiers

enum DiscoverTab: Equatable { case discover, mood, watchlist, search }
