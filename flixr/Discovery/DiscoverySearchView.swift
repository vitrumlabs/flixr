import SwiftUI
import FirebaseAnalytics

// MARK: - Screen 19: Search

struct DiscoverySearchView: View {
    var onClose: () -> Void
    var onOpenDetail: (Movie) -> Void

    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var isSearching = false
    @State private var trendingEntries: [TrendingEntry] = []
    @FocusState private var isSearchFocused: Bool

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

                        SearchField(text: $query, isFocused: $isSearchFocused, isSearching: isSearching)
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
            Task {
                trendingEntries = (try? await MovieService.shared.fetchTrending()) ?? []
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
                .padding(.bottom, 16)

            if trendingEntries.isEmpty {
                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { _ in
                        TrendingCardPlaceholder()
                    }
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(trendingEntries) { entry in
                            Button(action: { query = entry.name }) {
                                TrendingCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
                .transition(.opacity)
            }

            Spacer().frame(height: 32)
        }
        .animation(.easeIn(duration: 0.25), value: trendingEntries.isEmpty)
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

}

// MARK: - Search field

private struct SearchField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var isSearching: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color.dFg3)
                .symbolEffect(.bounce, value: isFocused.wrappedValue)
                .symbolEffect(.pulse, isActive: isSearching)
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

// MARK: - Trending card

private struct TrendingCard: View {
    let entry: TrendingEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                switch entry.kind {
                case .movie:
                    AsyncImage(url: entry.imageURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Color.white.opacity(0.06)
                        }
                    }
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )

                case .person:
                    AsyncImage(url: entry.imageURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color.white.opacity(0.25))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white.opacity(0.06))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .frame(width: 80, height: 120)

            Text(entry.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.dFg2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

private struct TrendingCardPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .frame(width: 80, height: 120)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.06))
                .frame(width: 60, height: 11)
        }
    }
}
