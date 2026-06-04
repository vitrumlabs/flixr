import Foundation
import FirebaseFunctions

// MARK: - TMDB genre ID → name

private let tmdbGenres: [Int: String] = [
    28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy",
    80: "Crime", 99: "Documentary", 18: "Drama", 10751: "Family",
    14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music",
    9648: "Mystery", 10749: "Romance", 878: "Sci-Fi", 10770: "TV Movie",
    53: "Thriller", 10752: "War", 37: "Western",
]

// MARK: - TMDB image helpers

enum TMDBImage {
    static let base = "https://image.tmdb.org/t/p/"

    static func posterURL(_ path: String, width: Int = 500) -> URL? {
        URL(string: "\(base)w\(width)\(path)")
    }

    static func backdropURL(_ path: String) -> URL? {
        URL(string: "\(base)w1280\(path)")
    }

    static func profileURL(_ path: String) -> URL? {
        URL(string: "\(base)w185\(path)")
    }

    static func logoURL(_ path: String) -> URL? {
        URL(string: "\(base)w92\(path)")
    }
}

// MARK: - Watch provider

struct WatchProvider: Identifiable, Hashable {
    let id: Int
    let name: String
    let logoPath: String?
}

// MARK: - Trending entry

struct TrendingEntry: Identifiable {
    let id: String
    let name: String
    let kind: Kind
    let imagePath: String?

    enum Kind: String { case movie, person }

    var imageURL: URL? {
        guard let path = imagePath else { return nil }
        switch kind {
        case .movie:  return TMDBImage.posterURL(path, width: 185)
        case .person: return TMDBImage.profileURL(path)
        }
    }
}

// MARK: - Service

struct MovieService {
    static let shared = MovieService()

    private let functions = Functions.functions(region: "europe-west1")

    func fetchPopular(page: Int = 1) async throws -> [Movie] {
        let result = try await functions.httpsCallable("getPopularMovies").call(["page": page])
        let root = result.data as? [String: Any] ?? [:]
        let results = root["results"] as? [[String: Any]] ?? []
        return results.compactMap { Movie(tmdb: $0) }
    }

    func fetchDetails(id: Int) async throws -> Movie {
        let result = try await functions.httpsCallable("getMovieDetails").call(["movieId": id])
        let data = result.data as? [String: Any] ?? [:]
        guard let movie = Movie(tmdbDetail: data) else { throw URLError(.badServerResponse) }
        return movie
    }

    func fetchWatchProviders(id: Int) async throws -> [WatchProvider] {
        let result = try await functions.httpsCallable("getWatchProviders").call(["movieId": id])
        let data = result.data as? [String: Any] ?? [:]
        let results = data["results"] as? [String: Any] ?? [:]
        let us = results["US"] as? [String: Any] ?? [:]
        let flatrate = us["flatrate"] as? [[String: Any]] ?? []
        return flatrate.compactMap { dict -> WatchProvider? in
            guard let name = dict["provider_name"] as? String,
                  let providerId = dict["provider_id"] as? Int else { return nil }
            return WatchProvider(id: providerId, name: name, logoPath: dict["logo_path"] as? String)
        }
    }

    func fetchTrending() async throws -> [TrendingEntry] {
        let result = try await functions.httpsCallable("getTrending").call()
        let root = result.data as? [String: Any] ?? [:]
        let items = root["trending"] as? [[String: Any]] ?? []
        return items.compactMap { dict -> TrendingEntry? in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let kindStr = dict["kind"] as? String,
                  let kind = TrendingEntry.Kind(rawValue: kindStr)
            else { return nil }
            return TrendingEntry(id: id, name: name, kind: kind,
                                 imagePath: dict["imagePath"] as? String)
        }
    }

    func search(query: String, page: Int = 1) async throws -> [Movie] {
        let result = try await functions.httpsCallable("searchMovies").call(["query": query, "page": page])
        let root = result.data as? [String: Any] ?? [:]
        let results = root["results"] as? [[String: Any]] ?? []
        return results.compactMap { Movie(tmdb: $0) }
    }

    func moodSearch(query: String) async throws -> [Movie] {
        let result = try await functions.httpsCallable("moodSearch").call(["query": query])
        let items = result.data as? [[String: Any]] ?? []
        return items.compactMap { Movie(moodResult: $0) }
    }

    func recommendations(watchlistIds: [String], seenIds: [String], count: Int = 10) async throws -> [Movie] {
        let result = try await functions.httpsCallable("getRecommendations").call([
            "watchlistIds": watchlistIds,
            "seenIds": seenIds,
            "count": count,
        ])
        let items = result.data as? [[String: Any]] ?? []
        return items.compactMap { Movie(tmdb: $0) }
    }

    func discover(filters: MovieFilters, page: Int = 1) async throws -> [Movie] {
        var payload: [String: Any] = [
            "page": page,
            "sortBy": filters.sortBy,
            "minRating": filters.minRating,
            "genres": Array(filters.genres),
            "includeAdult": false,
        ]
        if let decade = filters.decade {
            payload["decade"] = decade
        }
        if !filters.certifications.isEmpty {
            payload["certifications"] = Array(filters.certifications)
        }
        let result = try await functions.httpsCallable("discoverMovies").call(payload)
        let root = result.data as? [String: Any] ?? [:]
        let results = root["results"] as? [[String: Any]] ?? []
        return results.compactMap { Movie(tmdb: $0) }
    }
}

// MARK: - Movie ← mood search result (id + title + poster only)

extension Movie {
    init?(moodResult d: [String: Any]) {
        guard let tmdbId = d["id"] as? Int,
              let title = (d["title"] as? String)?.nilIfEmpty
        else { return nil }
        self.id          = String(tmdbId)
        self.title       = title
        self.year        = 0
        self.runtime     = ""
        self.genre       = "Film"
        self.genres      = []
        self.tag         = ""
        self.rating      = 0
        self.cert        = ""
        self.releaseDate = ""
        self.director    = ""
        self.studio      = ""
        self.language    = ""
        self.cast        = []
        self.platforms   = []
        self.palette     = MoviePalette.forGenre("")
        self.synopsis    = ""
        self.posterPath  = d["poster"] as? String
        self.backdropPath = nil
        self.trailerKey  = nil
    }
}

// MARK: - Movie ← TMDB list item (getPopularMovies / searchMovies)

extension Movie {
    init?(tmdb d: [String: Any]) {
        guard let tmdbId = d["id"] as? Int,
              let title = (d["title"] as? String)?.nilIfEmpty
        else { return nil }

        let rawDate    = d["release_date"] as? String ?? ""
        let year       = Int(rawDate.prefix(4)) ?? 0
        let genreIds   = d["genre_ids"] as? [Int] ?? []
        let genreNames = genreIds.compactMap { tmdbGenres[$0] }
        let primary    = genreNames.first ?? "Film"
        let langCode   = d["original_language"] as? String ?? ""
        let pop        = d["popularity"] as? Double ?? 0
        let votes      = d["vote_count"] as? Int ?? 0

        self.id          = String(tmdbId)
        self.title       = title
        self.year        = year
        self.runtime     = ""
        self.genre       = primary
        self.genres      = genreNames
        self.tag         = Self.tag(popularity: pop, votes: votes)
        self.rating      = ((d["vote_average"] as? Double ?? 0) * 10).rounded() / 10
        self.cert        = ""
        self.releaseDate = Self.formatDate(rawDate)
        self.director    = ""
        self.studio      = ""
        self.language    = Self.languageName(langCode)
        self.cast        = []
        self.platforms   = []
        self.palette      = MoviePalette.forGenre(primary)
        self.synopsis     = d["overview"] as? String ?? ""
        self.posterPath   = d["poster_path"] as? String
        self.backdropPath = nil
        self.trailerKey   = nil
    }
}

// MARK: - Movie ← TMDB detail item (getMovieDetails with credits)

extension Movie {
    init?(tmdbDetail d: [String: Any]) {
        guard let tmdbId = d["id"] as? Int,
              let title = (d["title"] as? String)?.nilIfEmpty
        else { return nil }

        let rawDate    = d["release_date"] as? String ?? ""
        let year       = Int(rawDate.prefix(4)) ?? 0
        let genreObjs  = d["genres"] as? [[String: Any]] ?? []
        let genreNames = genreObjs.compactMap { $0["name"] as? String }
        let primary    = genreNames.first ?? "Film"
        let langCode   = d["original_language"] as? String ?? ""
        let credits    = d["credits"] as? [String: Any] ?? [:]
        let castArray  = credits["cast"] as? [[String: Any]] ?? []
        let crewArray  = credits["crew"] as? [[String: Any]] ?? []
        let companies  = d["production_companies"] as? [[String: Any]] ?? []
        let pop        = d["popularity"] as? Double ?? 0
        let votes      = d["vote_count"] as? Int ?? 0

        let director = crewArray.first(where: { $0["job"] as? String == "Director" })?["name"] as? String ?? ""
        let castNames = castArray.prefix(5).compactMap { member -> CastMember? in
            guard let id = member["id"] as? Int,
                  let name = member["name"] as? String
            else { return nil }
            return CastMember(id: id, name: name, profilePath: member["profile_path"] as? String)
        }
        let studio    = companies.first?["name"] as? String ?? ""
        let runtime   = Self.formatRuntime(d["runtime"] as? Int)

        self.id          = String(tmdbId)
        self.title       = title
        self.year        = year
        self.runtime     = runtime
        self.genre       = primary
        self.genres      = genreNames
        self.tag         = Self.tag(popularity: pop, votes: votes)
        self.rating      = ((d["vote_average"] as? Double ?? 0) * 10).rounded() / 10
        self.cert        = d["cert"] as? String ?? ""
        self.releaseDate = Self.formatDate(rawDate)
        self.director    = director
        self.studio      = studio
        self.language    = Self.languageName(langCode)
        self.cast        = castNames
        self.platforms   = []
        self.palette      = MoviePalette.forGenre(primary)
        self.synopsis     = d["overview"] as? String ?? ""
        self.posterPath   = d["poster_path"] as? String
        self.backdropPath = d["backdrop_path"] as? String
        let videoResults  = (d["videos"] as? [String: Any])?["results"] as? [[String: Any]] ?? []
        self.trailerKey   = videoResults.first(where: {
            $0["type"] as? String == "Trailer" && $0["site"] as? String == "YouTube"
        })?["key"] as? String
    }
}

// MARK: - Formatting helpers

private extension Movie {
    static func formatRuntime(_ minutes: Int?) -> String {
        guard let m = minutes, m > 0 else { return "" }
        let h = m / 60, rem = m % 60
        return h > 0 ? "\(h)h \(rem)m" : "\(rem)m"
    }

    static func formatDate(_ raw: String) -> String {
        guard raw.count >= 10 else { return raw }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let date = df.date(from: String(raw.prefix(10))) else { return raw }
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }

    static func languageName(_ code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
    }

    static func tag(popularity: Double, votes: Int) -> String {
        if popularity > 200 { return "Trending" }
        if votes > 5000     { return "Popular" }
        return "Now Streaming"
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
