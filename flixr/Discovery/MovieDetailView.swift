import SwiftUI

// MARK: - Screen 21: Movie Detail

struct MovieDetailView: View {
    var movie: Movie
    var onClose: () -> Void

    @Environment(UserLibrary.self) private var library
    @Environment(\.openURL) private var openURL
    @State private var detail: Movie? = nil
    @State private var isFetching = false
    @State private var watchProviders: [String] = []

    private var displayed: Movie { detail ?? movie }
    private let heroHeight: CGFloat = 300

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
            }
            .ignoresSafeArea(edges: .top)
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
                    .init(color: .black.opacity(0.25), location: 0),
                    .init(color: .clear, location: 0.18),
                    .init(color: .clear, location: 0.4),
                    .init(color: .black.opacity(0.45), location: 0.65),
                    .init(color: .black.opacity(0.88), location: 0.88),
                    .init(color: .black, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )

            Button(action: openTrailer) {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
            }
            .glassEffect(in: Circle())
            .accessibilityLabel("Play trailer")
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
        .overlay(alignment: .topLeading) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(in: Circle())
            .accessibilityLabel("Close")
            .padding(.top, topSafeArea + 8)
            .padding(.leading, 16)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(displayed.title)
                .font(.flxDisplay(32))
                .tracking(-0.5)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            metaRow.padding(.top, 8)

            Text(displayed.synopsis)
                .font(.system(size: 15))
                .foregroundColor(Color.dFg2)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

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
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "FFD700"))
                    Text(String(format: "%.1f", displayed.rating))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))
                }
                ForEach(timeParts, id: \.self) { part in
                    DotSep()
                    Text(part).foregroundColor(Color.dFg2)
                }
            }
            .font(.system(size: 13))

            if !displayed.genres.isEmpty {
                HStack(spacing: 6) {
                    ForEach(displayed.genres, id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.dFg2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.dLine, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        let inWatchlist = library.watchlistIds.contains(displayed.id)
        return HStack(spacing: 10) {
            Button(action: openTrailer) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 14))
                    Text("Watch trailer").font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(LinearGradient(
                    colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                    startPoint: .top, endPoint: .bottom))
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.97))

            Button(action: {
                Task {
                    if inWatchlist { await library.removeFromWatchlist(displayed) }
                    else           { await library.addToWatchlist(displayed) }
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
            .accessibilityLabel(inWatchlist ? "Remove from watchlist" : "Add to watchlist")
        }
    }

    private var metadataSection: some View {
        VStack(spacing: 0) {
            MetaListRow(label: "Director",  value: displayed.director,    isLoading: isFetching)
            Rectangle().fill(Color.dLine).frame(height: 1).padding(.leading, 14)
            MetaListRow(label: "Studio",    value: displayed.studio,      isLoading: isFetching)
            Rectangle().fill(Color.dLine).frame(height: 1).padding(.leading, 14)
            MetaListRow(label: "Language",  value: displayed.language,    isLoading: false)
            Rectangle().fill(Color.dLine).frame(height: 1).padding(.leading, 14)
            MetaListRow(label: "Release",   value: displayed.releaseDate, isLoading: false)
            Rectangle().fill(Color.dLine).frame(height: 1).padding(.leading, 14)
            MetaListRow(label: "Rated",     value: displayed.cert,        isLoading: false)
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.dLine, lineWidth: 1))
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Where to Watch")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(watchProviders, id: \.self) { provider in
                        Text(provider)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.dLine, lineWidth: 1))
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
            .foregroundColor(Color.dFg3)
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
