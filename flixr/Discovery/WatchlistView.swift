import SwiftUI

// MARK: - Screen 22: Watchlist

struct WatchlistView: View {
    var onOpenDetail: (Movie) -> Void

    @State private var activeTab = "saved"
    @State private var sortLabel = "Recently added"

    private let tabs = [
        (id: "saved", label: "To Watch", count: 24),
        (id: "liked", label: "Liked", count: 38),
        (id: "seen",  label: "Seen",  count: 112),
    ]

    private var movieList: [Movie] {
        (movieCatalog + movieCatalog).prefix(7).map { $0 }
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "14070a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Watchlist")
                        .font(.flxDisplay(32))
                        .foregroundColor(.white)
                    Text("\(tabs.first(where: { $0.id == activeTab })?.count ?? 0) titles · \(sortLabel)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.dFg3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Segmented control
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.id) { tab in
                        let on = tab.id == activeTab
                        Button(action: { activeTab = tab.id }) {
                            HStack(spacing: 6) {
                                Text(tab.label)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("\(tab.count)")
                                    .font(.system(size: 11))
                                    .opacity(0.85)
                            }
                            .foregroundColor(on ? .white : Color.dFg2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                on
                                ? AnyView(LinearGradient(colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")], startPoint: .top, endPoint: .bottom))
                                : AnyView(Color.clear)
                            )
                            .clipShape(Capsule())
                            .shadow(color: on ? Color.flxRed.opacity(0.35) : .clear, radius: 7, y: 3)
                        }
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.dLine, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    // Sort row
                    HStack {
                        Text("All saved")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color.dFg3)
                        Spacer()
                        Button(action: {
                            sortLabel = sortLabel == "Recently added" ? "Highest rated" : "Recently added"
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 11))
                                Text(sortLabel)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.dLine, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    // Movie rows
                    VStack(spacing: 0) {
                        ForEach(Array(movieList.enumerated()), id: \.element.id) { i, movie in
                            WatchlistRow(movie: movie, isLast: i == movieList.count - 1) {
                                onOpenDetail(movie)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 110)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Watchlist row

private struct WatchlistRow: View {
    var movie: Movie
    var isLast: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                PosterArt(movie: movie, width: 72)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Text(movie.title)
                            .font(.flxDisplay(16))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "FFD700"))
                            Text(String(format: "%.1f", movie.rating))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                    }

                    Text("\(movie.year) · \(movie.runtime) · \(movie.genre)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dFg3)
                        .padding(.top, 4)

                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(Color.dFg3)
                                .frame(width: 30, height: 30)
                        }
                        .onTapGesture {}
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider()
                .background(Color.dLine)
        }
    }
}
