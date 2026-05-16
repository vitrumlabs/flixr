import Foundation
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore

// MARK: - Watchlist / liked snapshot stored in Firestore

struct MovieSnapshot {
    let id: String          // TMDB id as string
    let title: String
    let year: Int
    let runtime: String
    let genres: [String]
    let rating: Double
    let posterPath: String?

    /// Reconstruct a displayable Movie from the stored snapshot
    func asMovie() -> Movie {
        Movie(
            id: id,
            title: title,
            year: year,
            runtime: runtime,
            genre: genres.first ?? "Film",
            genres: genres,
            tag: "",
            rating: rating,
            cert: "",
            releaseDate: "",
            director: "",
            studio: "",
            language: "",
            cast: [],
            platforms: [],
            palette: MoviePalette.forGenre(genres.first ?? ""),
            synopsis: "",
            posterPath: posterPath,
            backdropPath: nil,
            trailerKey: nil
        )
    }

    init?(_ d: [String: Any]) {
        guard let rawId = d["id"],
              let title = d["title"] as? String
        else { return nil }
        self.id         = rawId is Int ? String(rawId as! Int) : rawId as? String ?? ""
        self.title      = title
        self.year       = d["year"]    as? Int    ?? 0
        self.runtime    = d["runtime"] as? String ?? ""
        self.genres     = d["genres"]  as? [String] ?? []
        self.rating     = d["rating"]  as? Double ?? 0
        self.posterPath = d["posterPath"] as? String
    }

    func toFirestore() -> [String: Any] {
        var d: [String: Any] = [
            "id":      Int(id) ?? 0,
            "title":   title,
            "year":    year,
            "runtime": runtime,
            "genres":  genres,
            "rating":  rating,
        ]
        if let path = posterPath { d["posterPath"] = path }
        return d
    }
}

// MARK: - UserLibrary

@Observable
final class UserLibrary {
    private(set) var watchlist: [MovieSnapshot] = []
    private(set) var liked: [MovieSnapshot]     = []

    // Derived from liked entries
    var topGenres: [String] {
        var counts: [String: Int] = [:]
        for snap in liked {
            for g in snap.genres { counts[g, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map(\.key)
    }

    var likedIds: Set<String> { Set(liked.map(\.id)) }

    private let db  = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Load

    func load() async {
        guard let uid else { return }
        guard let data = try? await db.collection("users").document(uid).getDocument().data()
        else { return }

        if let raw = data["watchlist"] as? [[String: Any]] {
            watchlist = raw.compactMap { MovieSnapshot($0) }
        }
        if let raw = data["liked"] as? [[String: Any]] {
            liked = raw.compactMap { MovieSnapshot($0) }
        }
    }

    // MARK: - Like

    func like(_ movie: Movie) async {
        guard let uid, !likedIds.contains(movie.id) else { return }
        let snap = movie.snapshot()
        let entry = snap.toFirestore()
        try? await db.collection("users").document(uid).updateData([
            "liked": FieldValue.arrayUnion([entry])
        ])
        liked.append(snap)
        Analytics.logMovieLiked(movie)
    }

    func unlike(_ movie: Movie) async {
        guard let uid, let snap = liked.first(where: { $0.id == movie.id }) else { return }
        let entry = snap.toFirestore()
        try? await db.collection("users").document(uid).updateData([
            "liked": FieldValue.arrayRemove([entry])
        ])
        liked.removeAll { $0.id == movie.id }
    }

    // MARK: - Skip

    func skip(_ movie: Movie) async {
        guard let uid else { return }
        let tmdbId = Int(movie.id) ?? 0
        try? await db.collection("users").document(uid).updateData([
            "skipped": FieldValue.arrayUnion([tmdbId])
        ])
        Analytics.logMovieSkipped(movie)
    }

    // MARK: - Watchlist

    func addToWatchlist(_ movie: Movie) async {
        guard let uid, !watchlistIds.contains(movie.id) else { return }
        let snap = movie.snapshot()
        let entry = snap.toFirestore()
        try? await db.collection("users").document(uid).updateData([
            "watchlist": FieldValue.arrayUnion([entry])
        ])
        watchlist.append(snap)
        Analytics.logWatchlistAdd(movie)
    }

    func removeFromWatchlist(_ movie: Movie) async {
        guard let uid, let snap = watchlist.first(where: { $0.id == movie.id }) else { return }
        let entry = snap.toFirestore()
        try? await db.collection("users").document(uid).updateData([
            "watchlist": FieldValue.arrayRemove([entry])
        ])
        watchlist.removeAll { $0.id == movie.id }
        Analytics.logWatchlistRemove(movie)
    }

    var watchlistIds: Set<String> { Set(watchlist.map(\.id)) }
}

// MARK: - Movie → snapshot

private extension Movie {
    func snapshot() -> MovieSnapshot {
        MovieSnapshot([
            "id":      Int(id) ?? 0,
            "title":   title,
            "year":    year,
            "runtime": runtime,
            "genres":  genres,
            "rating":  rating,
            "posterPath": posterPath as Any,
        ])!
    }
}
