import Foundation

/// Holds swipe deck state outside the view so navigation to MovieDetailView
/// and back doesn't reset the queue.
@Observable
final class DiscoverDeck {
    var movies: [Movie] = []
    var deckIndex: Int = 0
    var isLoading: Bool = false
    var fetchError: Bool = false
    var totalSwipes: Int = 0
    private var isLoadingMore: Bool = false

    // MARK: - Initial load

    func loadMovies(filters: MovieFilters) async {
        isLoading = true
        fetchError = false
        deckIndex = 0
        totalSwipes = 0
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

    // MARK: - Incremental load (AI or TMDB fallback)

    func loadMore(filters: MovieFilters) async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let seenIds = movies.map(\.id)
        var more: [Movie] = []

        if totalSwipes >= 5 {
            more = (try? await MovieService.shared.fetchRecommendations(seenIds: seenIds)) ?? []
        }

        if more.isEmpty {
            let nextPage = (movies.count / 20) + 1
            if filters.isActive {
                more = (try? await MovieService.shared.discover(filters: filters, page: nextPage)) ?? []
            } else {
                more = (try? await MovieService.shared.fetchPopular(page: nextPage)) ?? []
            }
        }

        movies.append(contentsOf: more.filter { m in !seenIds.contains(m.id) })
    }

    // MARK: - Silent background preload

    private func preloadTMDB(filters: MovieFilters, pages: ClosedRange<Int>) async {
        for page in pages {
            let seenIds = movies.map(\.id)
            if filters.isActive {
                guard let more = try? await MovieService.shared.discover(filters: filters, page: page)
                else { continue }
                movies.append(contentsOf: more.filter { m in !seenIds.contains(m.id) })
            } else {
                guard let more = try? await MovieService.shared.fetchPopular(page: page)
                else { continue }
                movies.append(contentsOf: more.filter { m in !seenIds.contains(m.id) })
            }
        }
    }
}
