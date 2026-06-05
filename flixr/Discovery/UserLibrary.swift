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

// MARK: - Notification preferences

struct NotificationPrefs {
    var newRecommendations: Bool = true
    var watchlistReminders: Bool = true
    var weeklyDigest:       Bool = true
}

// MARK: - UserLibrary

@Observable
final class UserLibrary {
    private(set) var watchlist:   [MovieSnapshot]   = []
    private(set) var isFlixrPlus: Bool              = false
    private(set) var notifPrefs:  NotificationPrefs = .init()

    var topGenres: [String] {
        var counts: [String: Int] = [:]
        for snap in watchlist {
            for g in snap.genres { counts[g, default: 0] += 1 }
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map(\.key)
    }

    var watchlistIds: Set<String> { Set(watchlist.map(\.id)) }

    /// Watchlist IDs ordered most-recently-added first, for use as recommendation seeds.
    var orderedWatchlistIds: [String] { watchlist.reversed().map(\.id) }

    private let db = Firestore.firestore()
    private var uid: String? { Auth.auth().currentUser?.uid }
    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    // MARK: - Listener

    func startListening(uid: String) {
        listener?.remove()
        let ref = db.collection("users").document(uid)
        listener = ref.addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let data = snapshot?.data() else { return }
            if let raw = data["watchlist"] as? [[String: Any]] {
                self.watchlist = raw.compactMap { MovieSnapshot($0) }
            }
            self.isFlixrPlus = data["isFlixrPlus"] as? Bool ?? false
            if let p = data["notificationPrefs"] as? [String: Any] {
                self.notifPrefs = NotificationPrefs(
                    newRecommendations: p["newRecommendations"] as? Bool ?? true,
                    watchlistReminders: p["watchlistReminders"] as? Bool ?? true,
                    weeklyDigest:       p["weeklyDigest"]       as? Bool ?? false
                )
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        watchlist   = []
        isFlixrPlus = false
        notifPrefs  = .init()
    }

    func saveNotifPrefs(_ prefs: NotificationPrefs) async {
        guard let uid else { return }
        notifPrefs = prefs
        try? await db.collection("users").document(uid).updateData([
            "notificationPrefs": [
                "newRecommendations": prefs.newRecommendations,
                "watchlistReminders": prefs.watchlistReminders,
                "weeklyDigest":       prefs.weeklyDigest,
            ]
        ])
    }

    // MARK: - Watchlist

    func addToWatchlist(_ movie: Movie) async {
        guard let uid, !watchlistIds.contains(movie.id) else { return }
        let snap = movie.snapshot()
        watchlist.append(snap)
        try? await db.collection("users").document(uid).updateData([
            "watchlist": FieldValue.arrayUnion([snap.toFirestore()])
        ])
        Analytics.logWatchlistAdd(movie)
    }

    func clearWatchlist() async {
        guard let uid else { return }
        watchlist = []
        try? await db.collection("users").document(uid).updateData(["watchlist": []])
    }

    func removeFromWatchlist(_ movie: Movie) async {
        guard let uid, let snap = watchlist.first(where: { $0.id == movie.id }) else { return }
        watchlist.removeAll { $0.id == movie.id }
        try? await db.collection("users").document(uid).updateData([
            "watchlist": FieldValue.arrayRemove([snap.toFirestore()])
        ])
        Analytics.logWatchlistRemove(movie)
    }
}

// MARK: - Movie → snapshot

private extension Movie {
    func snapshot() -> MovieSnapshot {
        MovieSnapshot([
            "id":         Int(id) ?? 0,
            "title":      title,
            "year":       year,
            "runtime":    runtime,
            "genres":     genres,
            "rating":     rating,
            "posterPath": posterPath as Any,
        ])!
    }
}
