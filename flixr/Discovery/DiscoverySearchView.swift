import SwiftUI
import FirebaseAnalytics

// MARK: - Screen 19: Search

struct DiscoverySearchView: View {
    var onClose: () -> Void
    var onOpenDetail: (Movie) -> Void
    var onBrowseGenre: ((String) -> Void)? = nil

    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    private let trending = ["Christopher Nolan", "Parasite", "Denis Villeneuve", "Oppenheimer", "Greta Gerwig"]

    private var hasQuery: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "0e060a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 450
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: onClose) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("Close")

                        SearchField(text: $query, isFocused: $isSearchFocused)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                ScrollView(showsIndicators: false) {
                    if hasQuery {
                        resultsContent
                    } else {
                        emptyStateContent
                    }
                }
            }
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isSearchFocused = true
            }
        }
        .preferredColorScheme(.dark)
        .task(id: query) {
            guard hasQuery else { results = []; return }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            isSearching = true
            results = (try? await MovieService.shared.search(query: query)) ?? []
            isSearching = false
            if !results.isEmpty { Analytics.logSearch(query) }
        }
    }

    // MARK: Empty state

    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Trending")
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)

            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(trending, id: \.self) { t in
                    Button(action: { query = t }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.flxRed)
                            Text(t)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .padding(.horizontal, 20)

            sectionHeader("Genres")
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(genreTiles, id: \.name) { tile in
                    Button(action: {
                        if let browse = onBrowseGenre {
                            browse(tile.name)
                        } else {
                            query = tile.name
                        }
                    }) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(colors: [tile.colorA, tile.colorB], startPoint: .topLeading, endPoint: .bottomTrailing)
                            Text(tile.name)
                                .font(.flxDisplay(18))
                                .tracking(-0.1)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 12)
                        }
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: Results state

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSearching {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            } else if results.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(Color.dFg3)
                    Text("No results for \"\(query)\"")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Try a different title, genre, or actor")
                        .font(.system(size: 14))
                        .foregroundColor(Color.dFg3)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                if let topMovie = results.first {
                    Button(action: { onOpenDetail(topMovie) }) {
                        ZStack(alignment: .bottomLeading) {
                            BackdropArt(movie: topMovie)
                                .aspectRatio(16 / 9, contentMode: .fit)

                            LinearGradient(
                                colors: [.clear, .black.opacity(0.85)],
                                startPoint: UnitPoint(x: 0.5, y: 0.3),
                                endPoint: .bottom
                            )

                            HStack(alignment: .bottom, spacing: 12) {
                                PosterArt(movie: topMovie, width: 56)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Top result")
                                        .font(.system(size: 10.5, weight: .bold))
                                        .tracking(1.6)
                                        .textCase(.uppercase)
                                        .foregroundColor(.flxRed)
                                    Text(topMovie.title)
                                        .font(.flxDisplay(20))
                                        .foregroundColor(.white)
                                    Text([String(topMovie.year), topMovie.runtime, topMovie.genre]
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " · "))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.dFg2)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "FFD700"))
                                    Text(String(format: "%.1f", topMovie.rating))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "FFD700"))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.55), radius: 18, y: 9)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }

                if results.count > 1 {
                    VStack(spacing: 0) {
                        ForEach(Array(results.dropFirst().prefix(9).enumerated()), id: \.element.id) { i, movie in
                            Button(action: { onOpenDetail(movie) }) {
                                HStack(spacing: 12) {
                                    PosterArt(movie: movie, width: 52)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(movie.title)
                                            .font(.flxDisplay(15))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Text([String(movie.year), movie.genre]
                                            .filter { !$0.isEmpty }
                                            .joined(separator: " · "))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.dFg3)
                                    }
                                    Spacer()
                                    HStack(spacing: 3) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(hex: "FFD700"))
                                        Text(String(format: "%.1f", movie.rating))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Color(hex: "FFD700"))
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.dFg3)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                            }
                            if i < min(results.count - 2, 8) {
                                Divider().background(Color.dLine).padding(.leading, 84)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(Color.dFg3)
    }

    private var genreTiles: [(name: String, colorA: Color, colorB: Color)] {[
        (name: "Sci-Fi",   colorA: Color(hex: "3a1556"), colorB: Color(hex: "1a0a30")),
        (name: "Drama",    colorA: Color(hex: "4a2810"), colorB: Color(hex: "1a0e05")),
        (name: "Thriller", colorA: Color(hex: "0d2a4a"), colorB: Color(hex: "040d1a")),
        (name: "Horror",   colorA: Color(hex: "3d0a12"), colorB: Color(hex: "1a0608")),
        (name: "Romance",  colorA: Color(hex: "0e3a3a"), colorB: Color(hex: "031414")),
        (name: "Western",  colorA: Color(hex: "5a2a08"), colorB: Color(hex: "1f1004")),
    ]}
}

// MARK: - Search field

private struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.dFg3)
            TextField("Search by title or person…", text: $text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.flxRed)
                .focused(isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - Flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineH + lineSpacing
                x = 0; lineH = 0
            }
            lineH = max(lineH, size.height)
            x += size.width + spacing
        }
        return CGSize(width: maxWidth, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineH + lineSpacing
                x = bounds.minX; lineH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            lineH = max(lineH, size.height)
            x += size.width + spacing
        }
    }
}
