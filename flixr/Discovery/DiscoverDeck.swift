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
            let batch: [Movie]
            if filters.isActive {
                batch = try await MovieService.shared.discover(filters: filters, page: 1)
            } else {
                // Random starting page so each session feels fresh
                let page = Int.random(in: 1...8)
                batch = try await MovieService.shared.fetchPopular(page: page)
            }
            movies = Array(batch.filter { !watchlistIds.contains($0.id) }.shuffled().prefix(10))
            isLoading = false
            Task { await preloadTMDB(filters: filters, watchlistIds: watchlistIds, count: 2) }
        } catch {
            fetchError = true
            isLoading = false
        }
    }

    // MARK: - Incremental TMDB load

    func refillIfNeeded(filters: MovieFilters, watchlistIds: Set<String> = []) async {
        let remaining = movies.count - deckIndex
        guard remaining < 15, !isLoadingMore else { return }
        isLoadingMore = true
        isRefilling = true
        defer { isLoadingMore = false; isRefilling = false }

        let seenIds = Set(movies.map(\.id))
        let excludedIds = seenIds.union(watchlistIds)
        let more: [Movie]
        if filters.isActive {
            let nextPage = (movies.count / 20) + 1
            more = (try? await MovieService.shared.discover(filters: filters, page: nextPage)) ?? []
            movies.append(contentsOf: more.filter { !excludedIds.contains($0.id) })
        } else {
            // Random page each time — dedup via excludedIds handles any overlap
            let page = Int.random(in: 1...20)
            more = (try? await MovieService.shared.fetchPopular(page: page)) ?? []
            movies.append(contentsOf: more.shuffled().filter { !excludedIds.contains($0.id) })
        }
    }

    // MARK: - Silent background preload

    private func preloadTMDB(filters: MovieFilters, watchlistIds: Set<String>, count: Int) async {
        for _ in 0..<count {
            let seenIds = Set(movies.map(\.id))
            let excludedIds = seenIds.union(watchlistIds)
            let more: [Movie]
            if filters.isActive {
                let nextPage = (movies.count / 20) + 1
                more = (try? await MovieService.shared.discover(filters: filters, page: nextPage)) ?? []
                movies.append(contentsOf: more.filter { !excludedIds.contains($0.id) })
            } else {
                let page = Int.random(in: 1...20)
                more = (try? await MovieService.shared.fetchPopular(page: page)) ?? []
                movies.append(contentsOf: more.shuffled().filter { !excludedIds.contains($0.id) })
            }
        }
    }
}
