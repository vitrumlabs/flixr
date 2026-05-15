import Foundation

/// Holds swipe deck state outside the view so navigation to MovieDetailView
/// and back doesn't reset the queue.
///
/// Two independent loading lanes:
///   - TMDB lane: keeps the deck full at all times (fast, no AI wait)
///   - AI lane:   runs in the background every 5 swipes and splices smarter
///               picks 5 positions ahead of the current card
@Observable
final class DiscoverDeck {
    var movies: [Movie] = []
    var deckIndex: Int = 0
    var isLoading: Bool = true
    var fetchError: Bool = false
    var totalSwipes: Int = 0
    var isRefilling: Bool = false

    private var isLoadingAI: Bool = false
    private var lastAISwipeCount: Int = -999

    // MARK: - Initial load

    func loadMovies(filters: MovieFilters) async {
        isLoading = true
        fetchError = false
        deckIndex = 0
        totalSwipes = 0
        lastAISwipeCount = -999
        movies = []
        do {
            let page1 = filters.isActive
                ? try await MovieService.shared.discover(filters: filters, page: 1)
                : try await MovieService.shared.fetchPopular(page: 1)
            movies = Array(page1.prefix(10))
            isLoading = false
            Task { await preloadTMDB(filters: filters, pages: 2...3) }
        } catch {
            fetchError = true
            isLoading = false
        }
    }

    // MARK: - TMDB lane: keeps deck full, fast, silent

    func refillIfNeeded(filters: MovieFilters) async {
        let remaining = movies.count - deckIndex
        guard remaining < 15, !isRefilling else { return }
        isRefilling = true
        defer { isRefilling = false }

        let seenIds = Set(movies.map(\.id))
        let nextPage = (movies.count / 20) + 1
        let more: [Movie]
        if filters.isActive {
            more = (try? await MovieService.shared.discover(filters: filters, page: nextPage)) ?? []
        } else {
            more = (try? await MovieService.shared.fetchPopular(page: nextPage)) ?? []
        }
        movies.append(contentsOf: more.filter { !seenIds.contains($0.id) })
    }

    // MARK: - AI lane: background splice, progressively smarter

    func spliceAIRecommendations(filters: MovieFilters) async {
        guard totalSwipes >= 5,
              totalSwipes - lastAISwipeCount >= 5,
              !isLoadingAI else { return }
        isLoadingAI = true
        lastAISwipeCount = totalSwipes
        defer { isLoadingAI = false }

        let seenIds = movies.map(\.id)
        guard let recs = try? await MovieService.shared.fetchRecommendations(
            seenIds: seenIds, filters: filters
        ), !recs.isEmpty else { return }

        let newMovies = recs.filter { !seenIds.contains($0.id) }
        guard !newMovies.isEmpty else { return }

        // Insert 5 positions ahead so AI picks surface naturally with no visible seam
        let insertAt = min(deckIndex + 5, movies.count)
        let replaceCount = min(newMovies.count, movies.count - insertAt)
        if replaceCount > 0 {
            movies.removeSubrange(insertAt..<(insertAt + replaceCount))
        }
        movies.insert(contentsOf: newMovies, at: insertAt)
    }

    // MARK: - Silent background preload

    private func preloadTMDB(filters: MovieFilters, pages: ClosedRange<Int>) async {
        for page in pages {
            let seenIds = Set(movies.map(\.id))
            let more: [Movie]
            if filters.isActive {
                more = (try? await MovieService.shared.discover(filters: filters, page: page)) ?? []
            } else {
                more = (try? await MovieService.shared.fetchPopular(page: page)) ?? []
            }
            movies.append(contentsOf: more.filter { !seenIds.contains($0.id) })
        }
    }
}
