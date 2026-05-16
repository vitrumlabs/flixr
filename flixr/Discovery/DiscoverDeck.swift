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

    func loadMovies(filters: MovieFilters) async {
        isLoading = true
        fetchError = false
        deckIndex = 0
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

    // MARK: - Incremental TMDB load

    func refillIfNeeded(filters: MovieFilters) async {
        let remaining = movies.count - deckIndex
        guard remaining < 15, !isLoadingMore else { return }
        isLoadingMore = true
        isRefilling = true
        defer { isLoadingMore = false; isRefilling = false }

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
