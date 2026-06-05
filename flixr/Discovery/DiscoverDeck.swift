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
    private var sessionLikeCount: Int = 0

    // MARK: - Initial load

    func loadMovies(
        filters: MovieFilters,
        watchlistIds: [String] = [],
        topGenres: [String] = []
    ) async {
        isLoading = true
        fetchError = false
        deckIndex = 0
        movies = []
        let excludeSet = Set(watchlistIds)
        do {
            var batch = try await fetchBatch(
                filters: filters,
                watchlistIds: watchlistIds,
                topGenres: topGenres,
                excludeIds: excludeSet
            )
            batch = batch.filter { !excludeSet.contains($0.id) }
            movies = Array(batch.shuffled().prefix(10))
            isLoading = false
        } catch {
            fetchError = true
            isLoading = false
        }
    }

    // MARK: - Incremental refill (fires when deck runs low)

    func refillIfNeeded(
        filters: MovieFilters,
        watchlistIds: [String] = [],
        topGenres: [String] = []
    ) async {
        let remaining = movies.count - deckIndex
        guard remaining < 6, !isLoadingMore else { return }
        isLoadingMore = true
        isRefilling = true
        defer { isLoadingMore = false; isRefilling = false }

        let seenIds = Set(movies.map(\.id))
        let excludeSet = seenIds.union(Set(watchlistIds))
        let more = (try? await fetchBatch(
            filters: filters,
            watchlistIds: watchlistIds,
            topGenres: topGenres,
            excludeIds: excludeSet
        )) ?? []
        movies.append(contentsOf: more.filter { !excludeSet.contains($0.id) })
    }

    // MARK: - Post-like fetch (fires immediately after each right swipe)

    func onLiked(
        filters: MovieFilters,
        watchlistIds: [String],
        topGenres: [String]
    ) async {
        sessionLikeCount += 1
        // Refresh every 3rd like — avoids overcorrecting on a short run of
        // similar content (e.g. 2 animated swipes dominating the taste vector).
        guard sessionLikeCount % 3 == 0, !isLoadingMore else { return }
        let seenIds = Set(movies.map(\.id))
        let excludeSet = seenIds.union(Set(watchlistIds))
        let fresh = (try? await fetchBatch(
            filters: filters,
            watchlistIds: watchlistIds,
            topGenres: topGenres,
            excludeIds: excludeSet
        )) ?? []
        movies.append(contentsOf: fresh.filter { !excludeSet.contains($0.id) })
    }

    // MARK: - Routing

    /// Fetches a batch using the best available source:
    ///  1. watchlistIds non-empty → vector recommendations
    ///     └ empty result → genre-matched discover (seamless fallback)
    ///        └ no genres → popular
    ///  2. filters active → discover
    ///  3. otherwise → popular (random page)
    private func fetchBatch(
        filters: MovieFilters,
        watchlistIds: [String],
        topGenres: [String],
        excludeIds: Set<String>
    ) async throws -> [Movie] {
        // 50:50 blend: fetch personalized recs and random popular simultaneously
        if !watchlistIds.isEmpty && !filters.isActive {
            async let recsFetch = MovieService.shared.recommendations(
                watchlistIds: watchlistIds,
                seenIds: Array(excludeIds),
                count: 20,
                filters: filters
            )
            let randomPage = Int.random(in: 1...20)
            async let popularFetch = MovieService.shared.fetchPopular(page: randomPage)

            let recs    = (try? await recsFetch)    ?? []
            let popular = (try? await popularFetch) ?? []

            let recsFiltered    = recs.filter    { !excludeIds.contains($0.id) }
            let recsIds         = Set(recsFiltered.map(\.id))
            let popularFiltered = popular.filter { !excludeIds.contains($0.id) && !recsIds.contains($0.id) }

            let combined = recsFiltered + popularFiltered
            if !combined.isEmpty { return combined }
            // Both empty — fall through to single-source paths below
        }

        // Explicit filters active: use discover endpoint only
        if filters.isActive {
            let page = (movies.count / 20) + 1
            return try await MovieService.shared.discover(filters: filters, page: page)
        }

        // No watchlist yet: random popular
        let page = Int.random(in: 1...20)
        return ((try? await MovieService.shared.fetchPopular(page: page)) ?? []).shuffled()
    }
}
