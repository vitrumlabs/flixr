import Testing
@testable import flixr

// MARK: - MovieFilters

struct MovieFiltersTests {

    @Test func defaultIsNotActive() {
        #expect(MovieFilters.default.isActive == false)
    }

    @Test func activeWhenGenreSelected() {
        var f = MovieFilters()
        f.genres = ["Action"]
        #expect(f.isActive)
    }

    @Test func activeWhenDecadeSelected() {
        var f = MovieFilters()
        f.decade = "2020s"
        #expect(f.isActive)
    }

    @Test func activeWhenSortNotDefault() {
        var f = MovieFilters()
        f.sortBy = "Top Rated"
        #expect(f.isActive)
    }

    @Test func activeWhenMinRatingSet() {
        var f = MovieFilters()
        f.minRating = 70
        #expect(f.isActive)
    }

    @Test func notActiveWhenAllDefault() {
        let f = MovieFilters(genres: [], decade: nil, sortBy: "Popular", minRating: 0)
        #expect(f.isActive == false)
    }
}

// MARK: - Movie(tmdbDetail:)

struct MovieTmdbDetailDecoderTests {

    private func baseDict() -> [String: Any] {
        [
            "id": 155,
            "title": "The Dark Knight",
            "release_date": "2008-07-18",
            "genres": [["id": 28, "name": "Action"], ["id": 80, "name": "Crime"]],
            "original_language": "en",
            "popularity": 100.0,
            "vote_count": 10000,
            "vote_average": 8.5,
            "overview": "Batman faces the Joker.",
            "runtime": 152,
            "production_companies": [["name": "Warner Bros."]],
            "credits": [
                "crew": [["job": "Director", "name": "Christopher Nolan"]],
                "cast": [
                    ["id": 1, "name": "Christian Bale", "profile_path": "/bale.jpg"],
                ],
            ],
            "videos": ["results": [] as [[String: Any]]],
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
        ]
    }

    @Test func populatesCertFromResponse() {
        var d = baseDict()
        d["cert"] = "PG-13"
        let movie = Movie(tmdbDetail: d)
        #expect(movie?.cert == "PG-13")
    }

    @Test func certDefaultsToEmptyWhenMissing() {
        let movie = Movie(tmdbDetail: baseDict())
        #expect(movie?.cert == "")
    }

    @Test func certDefaultsToEmptyWhenNil() {
        var d = baseDict()
        d["cert"] = nil
        let movie = Movie(tmdbDetail: d)
        #expect(movie?.cert == "")
    }

    @Test func populatesBasicFields() {
        let movie = Movie(tmdbDetail: baseDict())
        #expect(movie?.title == "The Dark Knight")
        #expect(movie?.year == 2008)
        #expect(movie?.director == "Christopher Nolan")
        #expect(movie?.studio == "Warner Bros.")
        #expect(movie?.runtime == "2h 32m")
        #expect(movie?.genre == "Action")
        #expect(movie?.genres == ["Action", "Crime"])
    }

    @Test func populatesPosterAndBackdrop() {
        let movie = Movie(tmdbDetail: baseDict())
        #expect(movie?.posterPath == "/poster.jpg")
        #expect(movie?.backdropPath == "/backdrop.jpg")
    }

    @Test func ratingRoundedToOneDecimal() {
        let movie = Movie(tmdbDetail: baseDict())
        #expect(movie?.rating == 8.5)
    }

    @Test func returnsNilForMissingId() {
        var d = baseDict()
        d.removeValue(forKey: "id")
        #expect(Movie(tmdbDetail: d) == nil)
    }

    @Test func returnsNilForEmptyTitle() {
        var d = baseDict()
        d["title"] = ""
        #expect(Movie(tmdbDetail: d) == nil)
    }
}

// MARK: - Movie(tmdb:)

struct MovieTmdbListDecoderTests {

    private func baseDict() -> [String: Any] {
        [
            "id": 27205,
            "title": "Inception",
            "release_date": "2010-07-16",
            "genre_ids": [878, 28],
            "original_language": "en",
            "popularity": 150.0,
            "vote_count": 5000,
            "vote_average": 8.3,
            "overview": "A thief who steals corporate secrets.",
            "poster_path": "/inception.jpg",
        ]
    }

    @Test func certAlwaysEmpty() {
        let movie = Movie(tmdb: baseDict())
        #expect(movie?.cert == "")
    }

    @Test func populatesYear() {
        let movie = Movie(tmdb: baseDict())
        #expect(movie?.year == 2010)
    }

    @Test func populatesGenres() {
        let movie = Movie(tmdb: baseDict())
        #expect(movie?.genres.contains("Sci-Fi") == true)
        #expect(movie?.genres.contains("Action") == true)
    }

    @Test func returnsNilForMissingId() {
        var d = baseDict()
        d.removeValue(forKey: "id")
        #expect(Movie(tmdb: d) == nil)
    }
}

// MARK: - Movie(moodResult:)

struct MovieMoodResultDecoderTests {

    @Test func populatesMinimalFields() {
        let d: [String: Any] = ["id": 99, "title": "Interstellar", "poster": "/inter.jpg"]
        let movie = Movie(moodResult: d)
        #expect(movie?.id == "99")
        #expect(movie?.title == "Interstellar")
        #expect(movie?.posterPath == "/inter.jpg")
        #expect(movie?.cert == "")
    }

    @Test func returnsNilForMissingTitle() {
        let d: [String: Any] = ["id": 99]
        #expect(Movie(moodResult: d) == nil)
    }
}
