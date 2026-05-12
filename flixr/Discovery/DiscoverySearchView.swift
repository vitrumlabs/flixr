import SwiftUI
import FirebaseAnalytics

// MARK: - Screen 19: Search

struct DiscoverySearchView: View {
    var onClose: () -> Void
    var onOpenDetail: (Movie) -> Void

    @State private var query = ""
    @State private var scope = "All"
    @State private var results: [Movie] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    private let scopes = ["All", "Movies", "Cast", "Genres", "Lists"]
    private let recents = ["Sci-Fi 2024", "Christopher Nolan", "Coast Road", "Indie horror", "A24"]
    private let trending = ["Cozy thrillers", "Heist films", "Awards season", "Korean cinema", "Slow burns"]

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
                // Header
                HStack(spacing: 10) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(in: Circle())
                    .accessibilityLabel("Close")

                    SearchField(text: $query, isFocused: $isSearchFocused)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Scope chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(scopes, id: \.self) { s in
                            ScopeChip(label: s, isActive: s == scope) { scope = s }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    if hasQuery {
                        resultsContent
                    } else {
                        emptyStateContent
                    }
                }
            }
        }
        .onAppear { isSearchFocused = true }
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
            HStack {
                sectionHeader("Recent")
                Spacer()
                Button("Clear") {}
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.flxRed)
                    .padding(.trailing, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(Array(recents.enumerated()), id: \.element) { i, r in
                    Button(action: { query = r }) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 15))
                                .foregroundColor(Color.dFg3)
                                .frame(width: 18)
                            Text(r)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12))
                                .foregroundColor(Color.dFg3)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                    if i < recents.count - 1 {
                        Divider().background(Color.dLine).padding(.leading, 50)
                    }
                }
            }

            sectionHeader("Trending searches")
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

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
                        .background(Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.dLine, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)

            sectionHeader("Browse by genre")
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(genreTiles, id: \.name) { tile in
                    Button(action: { query = tile.name }) {
                        Text(tile.name)
                            .font(.flxDisplay(18))
                            .tracking(-0.1)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(height: 64)
                            .background(
                                LinearGradient(colors: [tile.colorA, tile.colorB], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.dLine, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: Results state

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSearching {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                Text("\(results.count) results for \"\(query)\"")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(Color.dFg3)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                // Top result hero
                if let topMovie = results.first {
                    Button(action: { onOpenDetail(topMovie) }) {
                        ZStack(alignment: .bottomLeading) {
                            BackdropArt(movie: topMovie)
                                .aspectRatio(16 / 9, contentMode: .fit)

                            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: UnitPoint(x: 0.5, y: 0.3), endPoint: .bottom)

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
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
                        .shadow(color: .black.opacity(0.55), radius: 18, y: 9)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                // More results list
                if results.count > 1 {
                    Text("More results")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color.dFg3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

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
            TextField("Search movies, cast, genres…", text: $text)
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
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(
                !text.isEmpty ? Color.flxRed.opacity(0.55) : Color.dLine,
                lineWidth: 1
            )
        )
        .shadow(color: !text.isEmpty ? Color.flxRed.opacity(0.12) : .clear, radius: 4)
    }
}

// MARK: - Scope chip

private struct ScopeChip: View {
    var label: String
    var isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? .white : Color.dFg2)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(
                    isActive
                    ? AnyView(LinearGradient(colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")], startPoint: .top, endPoint: .bottom))
                    : AnyView(Color.white.opacity(0.04))
                )
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isActive ? Color.clear : Color.dLine, lineWidth: 1))
                .shadow(color: isActive ? Color.flxRed.opacity(0.32) : .clear, radius: 7, y: 3)
        }
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Flow layout (for trending chips wrapping)

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
