import SwiftUI

// MARK: - Screen 21: Movie Detail

struct MovieDetailView: View {
    var movie: Movie
    var onClose: () -> Void

    @Environment(UserLibrary.self) private var library
    @State private var detail: Movie? = nil
    @State private var isFetching = false

    private var displayed: Movie { detail ?? movie }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero backdrop
                    ZStack(alignment: .bottom) {
                        BackdropArt(movie: displayed, aspectRatio: 16 / 10)
                            .frame(maxWidth: .infinity)

                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.35), location: 0),
                                .init(color: .clear, location: 0.35),
                                .init(color: .clear, location: 0.6),
                                .init(color: .black.opacity(0.95), location: 1),
                            ],
                            startPoint: .top, endPoint: .bottom
                        )

                        Button(action: {}) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                        }
                        .glassEffect(in: Circle())
                        .frame(maxHeight: .infinity)

                        Button(action: onClose) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                        }
                        .glassEffect(in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.top, 52)
                        .padding(.leading, 16)
                    }
                    .frame(maxWidth: .infinity)

                    // Content
                    VStack(alignment: .leading, spacing: 0) {
                        Text(displayed.title)
                            .font(.flxDisplay(34))
                            .tracking(-0.5)
                            .foregroundColor(.white)
                            .padding(.top, 14)

                        // Meta row — skip empty segments
                        metaRow
                            .padding(.top, 8)

                        Text(displayed.synopsis)
                            .font(.system(size: 15))
                            .foregroundColor(Color.dFg2)
                            .lineSpacing(3)
                            .padding(.top, 16)

                        // Action buttons
                        HStack(spacing: 10) {
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                    Text("Watch trailer")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.97))

                            let inWatchlist = library.watchlistIds.contains(displayed.id)
                            Button(action: {
                                Task {
                                    if inWatchlist {
                                        await library.removeFromWatchlist(displayed)
                                    } else {
                                        await library.addToWatchlist(displayed)
                                    }
                                }
                            }) {
                                Image(systemName: inWatchlist ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(inWatchlist ? .flxRed : .white)
                                    .frame(width: 52, height: 48)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.dLine, lineWidth: 1))
                            }
                        }
                        .padding(.top, 22)

                        // Director / Studio / Language
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                            spacing: 10
                        ) {
                            InfoTile(key: "Director",  value: displayed.director,  isLoading: isFetching)
                            InfoTile(key: "Studio",    value: displayed.studio,    isLoading: isFetching)
                            InfoTile(key: "Language",  value: displayed.language,  isLoading: false)
                        }
                        .padding(.top, 26)

                        // Cast
                        if isFetching || !displayed.cast.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Cast")
                                if isFetching {
                                    ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(Array(displayed.cast.enumerated()), id: \.element) { i, name in
                                                CastAvatar(name: name, index: i)
                                            }
                                        }
                                        .padding(.horizontal, 1)
                                    }
                                }
                            }
                            .padding(.top, 26)
                        }

                        // Available on
                        if !displayed.platforms.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Available on")
                                FlexPlatforms(platforms: displayed.platforms)
                            }
                            .padding(.top, 22)
                        }

                        // Release / Rated
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            spacing: 10
                        ) {
                            InfoTile(key: "Release", value: displayed.releaseDate, isLoading: false)
                            InfoTile(key: "Rated",   value: displayed.cert,        isLoading: false)
                        }
                        .padding(.top, 22)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .preferredColorScheme(.dark)
        .task {
            guard let id = Int(movie.id) else { return }
            isFetching = true
            detail = try? await MovieService.shared.fetchDetails(id: id)
            isFetching = false
        }
    }

    // Only inserts DotSep between non-empty segments
    private var metaRow: some View {
        let segments: [String] = [
            String(format: "%.1f", displayed.rating),
            String(displayed.year),
            displayed.runtime,
            displayed.genre,
        ].filter { !$0.isEmpty && $0 != "0" }

        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                if i == 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FFD700"))
                        Text(seg)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "FFD700"))
                    }
                } else {
                    DotSep()
                    Text(seg).foregroundColor(Color.dFg2)
                }
            }
        }
        .font(.system(size: 14))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(Color.dFg3)
    }
}

// MARK: - Info tile

private struct InfoTile: View {
    var key: String
    var value: String
    var isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(Color.dFg3)
            if isLoading {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
            } else {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(value.isEmpty ? Color.dFg3 : .white)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.dLine, lineWidth: 1))
    }
}

// MARK: - Cast avatar

private struct CastAvatar: View {
    var name: String
    var index: Int

    private let palettes: [(Color, Color)] = [
        (Color(hex: "3a1556"), Color(hex: "1a0a30")),
        (Color(hex: "4a2810"), Color(hex: "1a0e05")),
        (Color(hex: "0d2a4a"), Color(hex: "040d1a")),
        (Color(hex: "3d0a12"), Color(hex: "1a0608")),
        (Color(hex: "5a2a08"), Color(hex: "1f1004")),
        (Color(hex: "0e3a3a"), Color(hex: "031414")),
    ]

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map { String($0) } }.joined()
    }
    private var firstName: String { name.components(separatedBy: " ").first ?? name }
    private var lastName: String { name.components(separatedBy: " ").dropFirst().joined(separator: " ") }

    var body: some View {
        let pal = palettes[index % palettes.count]
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [pal.0, pal.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .strokeBorder(Color.dLine, lineWidth: 1)
                Text(initials)
                    .font(.flxDisplay(18))
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)

            VStack(spacing: 1) {
                Text(firstName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(lastName)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color.dFg3)
            }
            .multilineTextAlignment(.center)
            .lineLimit(1)
        }
        .frame(width: 70)
    }
}

// MARK: - Platform chips

private struct FlexPlatforms: View {
    var platforms: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(platforms, id: \.self) { p in
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(colors: [Color(hex: "2a2a2e"), Color(hex: "0e0e10")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.dLine, lineWidth: 1))
                        Text(String(p.prefix(1)))
                            .font(.flxDisplay(11))
                            .foregroundColor(.white)
                    }
                    .frame(width: 22, height: 22)

                    Text(p)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.dLine, lineWidth: 1))
            }
            Spacer()
        }
    }
}
