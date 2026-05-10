import SwiftUI

// MARK: - Movie model

struct Movie: Identifiable, Equatable {
    let id: String
    let title: String
    let year: Int
    let runtime: String
    let genre: String
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

    static func == (lhs: Movie, rhs: Movie) -> Bool { lhs.id == rhs.id }
}

struct MoviePalette {
    let a: Color
    let b: Color
    let accent: Color
    let glow: Color
}

// MARK: - Catalog

let movieCatalog: [Movie] = [
    Movie(id: "m1", title: "Neon Halo", year: 2024, runtime: "1h 58m", genre: "Sci-Fi Noir",
          tag: "Now Streaming", rating: 8.2, cert: "R", releaseDate: "Mar 14, 2024",
          director: "L. Asari", studio: "Lumen Pictures", language: "English",
          cast: ["Aria Vance", "Ben Okafor", "Mira Sato", "Jonas Lehrer"],
          platforms: ["Netflix", "Prime Video", "Apple TV"],
          palette: MoviePalette(a: Color(hex: "3a1556"), b: Color(hex: "0a0418"), accent: Color(hex: "7c4dff"), glow: Color(hex: "22d3ee")),
          synopsis: "A burned-out detective chases a memory thief through the rain-slick neon of New Kowloon."),

    Movie(id: "m2", title: "Last Light", year: 2023, runtime: "2h 14m", genre: "Drama",
          tag: "Critic's Pick", rating: 7.9, cert: "PG-13", releaseDate: "Oct 06, 2023",
          director: "Mara Holt", studio: "North Sea Films", language: "English",
          cast: ["Ingrid Vale", "Theo Park", "Aoife Quinn"],
          platforms: ["MUBI", "Apple TV"],
          palette: MoviePalette(a: Color(hex: "4a2810"), b: Color(hex: "0e0805"), accent: Color(hex: "ff8a3c"), glow: Color(hex: "ffd089")),
          synopsis: "A lighthouse keeper and a stranded sailor pass one impossible winter on the edge of the world."),

    Movie(id: "m3", title: "The Atlas", year: 2025, runtime: "2h 02m", genre: "Thriller",
          tag: "New This Week", rating: 7.5, cert: "PG-13", releaseDate: "Jan 24, 2025",
          director: "Ryo Tanaka", studio: "Compass Bay", language: "English",
          cast: ["Noor Ali", "Sasha Greer", "Marcus Liu"],
          platforms: ["Max", "Hulu"],
          palette: MoviePalette(a: Color(hex: "0d2a4a"), b: Color(hex: "02080f"), accent: Color(hex: "4fa3ff"), glow: Color(hex: "bde0ff")),
          synopsis: "Six strangers wake aboard a cargo ship with no memory and a map that updates itself."),

    Movie(id: "m4", title: "Fever Dream", year: 2024, runtime: "1h 41m", genre: "Horror",
          tag: "Trending", rating: 7.1, cert: "R", releaseDate: "Aug 30, 2024",
          director: "Lia Solano", studio: "Hollow Pine", language: "Spanish",
          cast: ["Camila Rojas", "Diego Marín", "Lupe Ortiz"],
          platforms: ["Shudder", "Prime Video"],
          palette: MoviePalette(a: Color(hex: "3d0a12"), b: Color(hex: "0a0203"), accent: Color(hex: "ff2a3a"), glow: Color(hex: "ff8590")),
          synopsis: "After a heatwave hits the valley, a family begins to dream the same dream — and it is starting to bleed through."),

    Movie(id: "m5", title: "Sundown County", year: 2022, runtime: "2h 26m", genre: "Western",
          tag: "Award Winner", rating: 8.0, cert: "R", releaseDate: "Nov 11, 2022",
          director: "Jed Carver", studio: "Saltwater", language: "English",
          cast: ["Hank Doyle", "Esther Pine", "Wes Tully"],
          platforms: ["Netflix", "Prime Video"],
          palette: MoviePalette(a: Color(hex: "5a2a08"), b: Color(hex: "150804"), accent: Color(hex: "ff6a1a"), glow: Color(hex: "ffb37a")),
          synopsis: "A retired marshal is pulled back into one last hunt across the salt flats."),

    Movie(id: "m6", title: "Coast Road", year: 2023, runtime: "1h 47m", genre: "Romance",
          tag: "Indie Spotlight", rating: 7.6, cert: "PG-13", releaseDate: "Jun 02, 2023",
          director: "Niamh Brady", studio: "Tide & Co.", language: "English",
          cast: ["Cleo Marsh", "Sam Reyes"],
          platforms: ["Apple TV", "MUBI"],
          palette: MoviePalette(a: Color(hex: "0e3a3a"), b: Color(hex: "03100f"), accent: Color(hex: "5eead4"), glow: Color(hex: "fbcfe8")),
          synopsis: "Two strangers, one rental car, and the slow unspooling of an old Pacific highway."),
]
