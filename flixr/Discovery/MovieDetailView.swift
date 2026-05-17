import SwiftUI

// MARK: - Screen 21: Movie Detail

struct MovieDetailView: View {
    var movie: Movie
    var onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var detail: Movie? = nil
    @State private var isFetching = false
    @State private var watchProviders: [WatchProvider] = []

    private var displayed: Movie { detail ?? movie }
    private let heroHeight: CGFloat = 460

    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 44
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
                .containerRelativeFrame(.horizontal)
            }
            .ignoresSafeArea(edges: .top)

            // Back button floats above scroll content, anchored to physical top
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                    }
                    .glassEffect(.clear.interactive(), in: .circle)
                    .accessibilityLabel("Back")
                    .padding(.top, topSafeArea + 8)
                    .padding(.leading, 16)
                    Spacer()
                }
                Spacer()
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .task(id: movie.id) {
            detail = nil
            watchProviders = []
            isFetching = true
            guard let id = Int(movie.id) else { isFetching = false; return }
            async let detailFetch   = MovieService.shared.fetchDetails(id: id)
            async let providerFetch = MovieService.shared.fetchWatchProviders(id: id)
            detail         = try? await detailFetch
            watchProviders = (try? await providerFetch) ?? []
            isFetching = false
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            BackdropArt(movie: displayed, aspectRatio: 16 / 9)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.44),
                    .init(color: .black.opacity(0.52), location: 0.66),
                    .init(color: .black.opacity(0.92), location: 0.84),
                    .init(color: .black, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )

            Button(action: openTrailer) {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
            }
            .glassEffect(.clear.interactive(), in: .circle)
            .accessibilityLabel("Play trailer")
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(displayed.title)
                .font(.flxDisplay(36))
                .tracking(-0.8)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            metaRow.padding(.top, 8)

            Text(displayed.synopsis)
                .font(.system(size: 15))
                .foregroundStyle(Color.dFg2)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            actionButtons.padding(.top, 20)

            metadataSection.padding(.top, 24)

            if isFetching || !displayed.cast.isEmpty {
                castSection.padding(.top, 24)
            }

            if !watchProviders.isEmpty {
                whereToWatchSection.padding(.top, 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sub-sections

    private var metaRow: some View {
        let timeParts = [String(displayed.year), displayed.runtime].filter { !$0.isEmpty && $0 != "0" }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "FFD700"))
                    Text(String(format: "%.1f", displayed.rating))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                ForEach(timeParts, id: \.self) { part in
                    DotSep()
                    Text(part)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dFg2)
                }
            }

            if !displayed.genres.isEmpty {
                HStack(spacing: 6) {
                    ForEach(displayed.genres, id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(displayed.palette.accent.opacity(0.25))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(displayed.palette.accent.opacity(0.5), lineWidth: 1))
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        Button(action: openTrailer) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 14))
                Text("Watch trailer").font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LinearGradient(
                colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                startPoint: .top, endPoint: .bottom))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }

    private var metadataSection: some View {
        let items: [(String, String, Bool)] = [
            ("Director", displayed.director,    isFetching),
            ("Studio",   displayed.studio,      isFetching),
            ("Release",  displayed.releaseDate, false),
            ("Language", displayed.language,    false),
            ("Rated",    displayed.cert,        false),
        ]
        return GlassEffectContainer(spacing: 8) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(items, id: \.0) { label, value, loading in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(label)
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.dFg3)
                        if loading {
                            Capsule().fill(Color.white.opacity(0.1)).frame(height: 13)
                        } else {
                            Text(value.isEmpty ? "—" : value)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Cast")
            if isFetching {
                ProgressView().tint(.white)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(displayed.cast.enumerated()), id: \.offset) { i, member in
                            CastAvatar(member: member, index: i)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }

    private var whereToWatchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Where to Watch")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(watchProviders) { provider in
                        VStack(spacing: 8) {
                            Group {
                                if let path = provider.logoPath, let url = TMDBImage.logoURL(path) {
                                    AsyncImage(url: url) { phase in
                                        if case .success(let image) = phase {
                                            image.resizable().scaledToFit()
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.white.opacity(0.1))
                                        }
                                    }
                                    .id(url)
                                } else {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                }
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            Text(provider.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.dFg2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 64)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.45))
    }

    private func openTrailer() {
        if let key = displayed.trailerKey,
           let url = URL(string: "https://www.youtube.com/watch?v=\(key)") {
            openURL(url)
            return
        }
        let query = displayed.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://www.youtube.com/results?search_query=\(query)+official+trailer") {
            openURL(url)
        }
    }
}

// MARK: - Metadata list row

private struct MetaListRow: View {
    var label: String
    var value: String
    var isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.dFg3)
                .frame(width: 72, alignment: .leading)
            if isLoading {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 13)
            } else {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(value.isEmpty ? Color.dFg3 : .white)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Cast avatar

private struct CastAvatar: View {
    var member: CastMember
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
        member.name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }
    private var firstName: String { member.name.components(separatedBy: " ").first ?? member.name }
    private var lastName: String  { member.name.components(separatedBy: " ").dropFirst().joined(separator: " ") }

    var body: some View {
        let pal = palettes[index % palettes.count]
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(LinearGradient(colors: [pal.0, pal.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                if let path = member.profilePath, let url = TMDBImage.profileURL(path) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        }
                    }
                    .id(url)
                    .clipShape(Circle())
                } else {
                    Text(initials).font(.flxDisplay(18)).foregroundColor(.white)
                }
                Circle().strokeBorder(Color.dLine, lineWidth: 1)
            }
            .frame(width: 64, height: 64)
            VStack(spacing: 1) {
                Text(firstName).font(.system(size: 11.5, weight: .semibold)).foregroundColor(.white)
                Text(lastName).font(.system(size: 11)).foregroundColor(Color.dFg3)
            }
            .multilineTextAlignment(.center)
            .lineLimit(1)
        }
        .frame(width: 70)
    }
}
