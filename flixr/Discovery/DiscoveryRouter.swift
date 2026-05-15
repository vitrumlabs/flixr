import SwiftUI
import FirebaseAnalytics

// MARK: - Per-tab navigation state

private enum DiscoverNav: Equatable {
    case swipe
    case detail(Movie)
}

private enum WatchlistNav: Equatable {
    case list
    case detail(Movie)
}

// MARK: - Root flow

struct DiscoveryFlowView: View {
    @State private var activeTab: DiscoverTab = .discover
    @State private var discoverNav: DiscoverNav = .swipe
    @State private var discoverDeck = DiscoverDeck()
    @State private var watchlistNav: WatchlistNav = .list
    @State private var searchMovie: Movie? = nil
    @State private var showFilters = false
    @State private var showProfile = false
    @State private var activeFilters = MovieFilters.default

    var body: some View {
        TabView(selection: $activeTab) {
            Tab("Discover", systemImage: "movieclapper", value: DiscoverTab.discover) {
                discoverTab
                    .toolbar(discoverNav != .swipe || showFilters ? .hidden : .visible, for: .tabBar)
            }
            Tab("Mood", systemImage: "theatermasks", value: DiscoverTab.mood) {
                MoodPlaceholderView()
            }
            Tab("Watchlist", systemImage: "bookmark", value: DiscoverTab.watchlist) {
                watchlistTab
                    .toolbar(watchlistNav != .list ? .hidden : .visible, for: .tabBar)
            }
            Tab("Search", systemImage: "magnifyingglass", value: DiscoverTab.search, role: .search) {
                searchTab
            }
        }
        .tint(.flxRed)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: Discover tab

    private func randomizeFilters() {
        let allGenres = ["Action", "Adventure", "Animation", "Comedy", "Crime",
                         "Documentary", "Drama", "Fantasy", "History", "Horror",
                         "Music", "Mystery", "Romance", "Sci-Fi", "Thriller", "War", "Western"]
        let allDecades: [String?] = [nil, nil, "2020s", "2010s", "2000s", "90s", "80s", "Older"]
        let allSorts = ["Popular", "Top Rated", "Newest", "Blockbusters"]
        let ratingOptions: [Double] = [0, 0, 0, 5, 6, 7]

        let genres = Set(allGenres.shuffled().prefix(Int.random(in: 1...3)))
        let decade = allDecades.randomElement() ?? nil
        let sortBy = allSorts.randomElement() ?? "Popular"
        let minRating = ratingOptions.randomElement() ?? 0

        activeFilters = MovieFilters(genres: genres, decade: decade, sortBy: sortBy, minRating: minRating)
    }

    @ViewBuilder
    private var discoverTab: some View {
        ZStack {
            switch discoverNav {
            case .swipe:
                DiscoverSwipeScreen(
                    filters: activeFilters,
                    onOpenFilters: { withAnimation { showFilters = true } },
                    onOpenProfile: { showProfile = true },
                    onOpenDetail: { movie in
                        Analytics.logMovieDetailViewed(movie)
                        withAnimation { discoverNav = .detail(movie) }
                    },
                    onShuffle: {
                        Analytics.logShuffleTapped()
                        randomizeFilters()
                    }
                )
                .environment(discoverDeck)
            case .detail(let movie):
                MovieDetailView(movie: movie, onClose: { withAnimation { discoverNav = .swipe } })
                    .id(movie.id)
            }

            if showFilters {
                DiscoveryFiltersSheet(
                    initialFilters: activeFilters,
                    onApply: { newFilters in
                        activeFilters = newFilters
                        Analytics.logFiltersApplied(newFilters)
                        withAnimation { showFilters = false }
                    },
                    onClose: { withAnimation { showFilters = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: discoverNav)
        .animation(.easeInOut(duration: 0.25), value: showFilters)
    }

    // MARK: Watchlist tab

    @ViewBuilder
    private var watchlistTab: some View {
        ZStack {
            switch watchlistNav {
            case .list:
                WatchlistView(onOpenDetail: { movie in
                    Analytics.logMovieDetailViewed(movie)
                    withAnimation { watchlistNav = .detail(movie) }
                })
            case .detail(let movie):
                MovieDetailView(movie: movie, onClose: { withAnimation { watchlistNav = .list } })
                    .id(movie.id)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: watchlistNav)
    }

    // MARK: Search tab

    @ViewBuilder
    private var searchTab: some View {
        ZStack {
            if let movie = searchMovie {
                MovieDetailView(movie: movie, onClose: { withAnimation { searchMovie = nil } })
                    .id(movie.id)
            } else {
                DiscoverySearchView(
                    onClose: { withAnimation { activeTab = .discover } },
                    onOpenDetail: { movie in
                        Analytics.logMovieDetailViewed(movie)
                        withAnimation { searchMovie = movie }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.22), value: searchMovie?.id)
        .toolbar(searchMovie != nil ? .hidden : .visible, for: .tabBar)
    }
}
