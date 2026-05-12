import FirebaseAnalytics

// Typed wrappers around Analytics.logEvent so call sites stay clean and
// all event names / parameter keys are defined in one place.
extension Analytics {

    static func logMovieLiked(_ movie: Movie) {
        logEvent("movie_liked", parameters: [
            "movie_id": movie.id,
            "title": movie.title,
            "genre": movie.genre,
            "year": movie.year,
            "rating": movie.rating,
        ])
    }

    static func logMovieSkipped(_ movie: Movie) {
        logEvent("movie_skipped", parameters: [
            "movie_id": movie.id,
            "title": movie.title,
            "genre": movie.genre,
        ])
    }

    static func logWatchlistAdd(_ movie: Movie) {
        logEvent("watchlist_add", parameters: [
            "movie_id": movie.id,
            "title": movie.title,
            "genre": movie.genre,
        ])
    }

    static func logWatchlistRemove(_ movie: Movie) {
        logEvent("watchlist_remove", parameters: [
            "movie_id": movie.id,
            "title": movie.title,
        ])
    }

    // Uses the Firebase standard SelectContent event so it shows up in
    // the predefined "Content" reports in the Analytics dashboard.
    static func logMovieDetailViewed(_ movie: Movie) {
        logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterContentType: "movie",
            AnalyticsParameterItemID: movie.id,
            "title": movie.title,
            "genre": movie.genre,
        ])
    }

    // Uses the Firebase standard Search event so it shows up in the
    // predefined "Search terms" report.
    static func logSearch(_ query: String) {
        logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query,
        ])
    }

    static func logFiltersApplied(_ filters: MovieFilters) {
        logEvent("filters_applied", parameters: [
            "genres": filters.genres.sorted().joined(separator: ","),
            "sort_by": filters.sortBy,
            "decade": filters.decade ?? "any",
            "min_rating": filters.minRating,
        ])
    }

    static func logShuffleTapped() {
        logEvent("shuffle_triggered", parameters: nil)
    }
}
