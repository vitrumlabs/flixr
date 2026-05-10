import SwiftUI

// MARK: - Movie model

struct Movie: Identifiable, Equatable {
    let id: String
    let title: String
    let year: Int
    let runtime: String       // "1h 47m", or "" when not available from list endpoint
    let genre: String         // primary genre, e.g. "Sci-Fi"
    let genres: [String]      // all genres, e.g. ["Sci-Fi", "Drama"]
    let tag: String
    let rating: Double
    let cert: String
    let releaseDate: String
    let director: String
    let studio: String
    let language: String
    let cast: [String]
    let platforms: [String]
    let palette: MoviePalette
    let synopsis: String
    let posterPath: String?    // TMDB path, e.g. "/abc.jpg"
    let backdropPath: String?  // TMDB landscape backdrop path, only from detail endpoint

    static func == (lhs: Movie, rhs: Movie) -> Bool { lhs.id == rhs.id }
}

struct MoviePalette {
    let a: Color
    let b: Color
    let accent: Color
    let glow: Color

    // Genre-based defaults used when no poster is available
    static func forGenre(_ genre: String) -> MoviePalette {
        switch genre {
        case "Action":
            return MoviePalette(a: Color(hex: "3a0a0a"), b: Color(hex: "0a0202"), accent: Color(hex: "ff3333"), glow: Color(hex: "ff8080"))
        case "Adventure":
            return MoviePalette(a: Color(hex: "1a2a0a"), b: Color(hex: "060902"), accent: Color(hex: "72cc4a"), glow: Color(hex: "b8e890"))
        case "Animation":
            return MoviePalette(a: Color(hex: "1a0a3a"), b: Color(hex: "050210"), accent: Color(hex: "c084fc"), glow: Color(hex: "e9d5ff"))
        case "Comedy":
            return MoviePalette(a: Color(hex: "2a1a0a"), b: Color(hex: "080503"), accent: Color(hex: "fb923c"), glow: Color(hex: "fed7aa"))
        case "Crime":
            return MoviePalette(a: Color(hex: "0a0a1a"), b: Color(hex: "020205"), accent: Color(hex: "94a3b8"), glow: Color(hex: "cbd5e1"))
        case "Drama":
            return MoviePalette(a: Color(hex: "2a1a0a"), b: Color(hex: "080503"), accent: Color(hex: "e8943a"), glow: Color(hex: "f5c882"))
        case "Fantasy":
            return MoviePalette(a: Color(hex: "1a0a3a"), b: Color(hex: "050210"), accent: Color(hex: "7c4dff"), glow: Color(hex: "c5b0ff"))
        case "History":
            return MoviePalette(a: Color(hex: "3a2a0a"), b: Color(hex: "0e0a03"), accent: Color(hex: "d4a853"), glow: Color(hex: "f5d89a"))
        case "Horror":
            return MoviePalette(a: Color(hex: "1a0a0a"), b: Color(hex: "050202"), accent: Color(hex: "cc0000"), glow: Color(hex: "ff4444"))
        case "Mystery":
            return MoviePalette(a: Color(hex: "0a0a2a"), b: Color(hex: "02020a"), accent: Color(hex: "6366f1"), glow: Color(hex: "a5b4fc"))
        case "Romance":
            return MoviePalette(a: Color(hex: "3a0a28"), b: Color(hex: "0d0208"), accent: Color(hex: "ff69b4"), glow: Color(hex: "ffb6d9"))
        case "Sci-Fi", "Science Fiction":
            return MoviePalette(a: Color(hex: "0a1a3a"), b: Color(hex: "020510"), accent: Color(hex: "4fa3ff"), glow: Color(hex: "bde0ff"))
        case "Thriller":
            return MoviePalette(a: Color(hex: "0a1a2a"), b: Color(hex: "02050a"), accent: Color(hex: "3a7fbf"), glow: Color(hex: "8ab8e0"))
        case "War":
            return MoviePalette(a: Color(hex: "1a1a0a"), b: Color(hex: "050503"), accent: Color(hex: "84cc16"), glow: Color(hex: "d9f99d"))
        case "Western":
            return MoviePalette(a: Color(hex: "3a1a0a"), b: Color(hex: "0e0805"), accent: Color(hex: "e08040"), glow: Color(hex: "f0b080"))
        default:
            return MoviePalette(a: Color(hex: "1a1a2a"), b: Color(hex: "05050a"), accent: Color(hex: "7c4dff"), glow: Color(hex: "c5b0ff"))
        }
    }
}
