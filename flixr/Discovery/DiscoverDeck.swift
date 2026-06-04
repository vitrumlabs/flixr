import Foundation

/// Holds swipe deck state outside the view so navigation to MovieDetailView
/// and back doesn't reset the queue.
@Observable
final class DiscoverDeck {
    var movies: [Movie] = []
    var deckIndex: Int = 0
    var isLoading: Bool = true
    var fetchError: Bool = false
    var isRefilling: Bool = false

    private var isLoadingMore: Bool = false

    // MARK: - Initial load

    func loadMovies(filters: MovieFilters, watchlistIds: Set<String> = []) async {
        isLoading = true
        fetchError = false
        deckIndex = 0
        movies = []
        do {
            var batch = try await fetchBatch(
                filters: filters,
                watchlistIds: watchlistIds,
                excludeIds: watchlistIds
            )
            // Recommendations already exclude watchlistIds server-side;
            // the filter here covers the TMDB popular/discover fallback paths.
            batch = batch.filter { !watchlistIds.contains($0.id) }
            movies = Array(batch.shuffled().prefix(10))
            isLoading = false
            Task { await preload(filters: filters, watchlistIds: watchlistIds, count: 2) }
        } catch {
            fetchError = true
            isLoading = false
        }
    }

    // MARK: - Incremental load

    func refillIfNeeded(filters: MovieFilters, watchlistIds: Set<String> = []) async {
        let remaining = movies.count - deckIndex
        guard remaining < 15, !isLoadingMore else { return }
        isLoadingMore = true
        isRefilling = true
        defer { isLoadingMore = false; isRefilling = false }

        let seenIds = Set(movies.map(\.id))
        let excludedIds = seenIds.union(watchlistIds)
        let more = (try? await fetchBatch(
            filters: filters,
            watchlistIds: watchlistIds,
            excludeIds: excludedIds
        )) ?? []
        movies.append(contentsOf: more.filter { !excludedIds.contains($0.id) })
    }

    // MARK: - Silent background preload

    private func preload(filters: MovieFilters, watchlistIds: Set<String>, count: Int) async {
        for _ in 0..<count {
            let seenIds = Set(movies.map(\.id))
            let excludedIds = seenIds.union(watchlistIds)
            let more = (try? await fetchBatch(
                filters: filters,
                watchlistIds: watchlistIds,
                excludeIds: excludedIds
            )) ?? []
            movies.append(contentsOf: more.filter { !excludedIds.contains($0.id) })
        }
    }

    // MARK: - Routing

    /// Returns a batch of movies using the appropriate source:
    /// - Watchlist non-empty → vector recommendations from `getRecommendations`
    /// - Filters active → TMDB `discoverMovies`
    /// - Otherwise → TMDB popular (random page)
    private func fetchBatch(
        filters: MovieFilters,
        watchlistIds: Set<String>,
        excludeIds: Set<String>
    ) async throws -> [Movie] {
        if !watchlistIds.isEmpty {
            let recs = try await MovieService.shared.recommendations(
                watchlistIds: Array(watchlistIds),
                seenIds: Array(excludeIds),
                count: 20
            )
            if !recs.isEmpty { return recs }
            // Fall through to general discovery when no embeddings match
        }
        if filters.isActive {
            let page = (movies.count / 20) + 1
            return try await MovieService.shared.discover(filters: filters, page: page)
        } else {
            let page = Int.random(in: 1...20)
            return ((try? await MovieService.shared.fetchPopular(page: page)) ?? []).shuffled()
        }
    }
}
