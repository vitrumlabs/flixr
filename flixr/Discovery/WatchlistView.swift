import SwiftUI

// MARK: - Screen 22: Watchlist

struct WatchlistView: View {
    var onOpenDetail: (Movie) -> Void

    @Environment(UserLibrary.self) private var library
    @State private var sortOrder = SortOrder.recentlyAdded
    @State private var showClearConfirm = false

    private enum SortOrder: String, CaseIterable {
        case recentlyAdded = "Recently Added"
        case highestRated  = "Highest Rated"
    }

    private var allSaved: [MovieSnapshot] { library.watchlist }

    private var movieList: [Movie] {
        let sorted = sortOrder == .highestRated
            ? allSaved.sorted { $0.rating > $1.rating }
            : allSaved.reversed()
        return sorted.map { $0.asMovie() }
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
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(allSaved.count) title\(allSaved.count == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(Color.dFg3)
                    }
                    Spacer()
                    Menu {
                        Picker("Sort by", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        if !allSaved.isEmpty {
                            Divider()
                            Button(role: .destructive) {
                                showClearConfirm = true
                            } label: {
                                Label("Clear Watchlist", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 22))
                            .foregroundColor(Color.dFg2)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Sort watchlist")
                    .confirmationDialog(
                        "Clear Watchlist",
                        isPresented: $showClearConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Clear All", role: .destructive) {
                            Task { await library.clearWatchlist() }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will remove all \(allSaved.count) title\(allSaved.count == 1 ? "" : "s") from your watchlist.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    if movieList.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(movieList.enumerated()), id: \.element.id) { i, movie in
                                WatchlistRow(movie: movie, isLast: i == movieList.count - 1) {
                                    onOpenDetail(movie)
                                } onRemove: {
                                    Task {
                                        await library.removeFromWatchlist(movie)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 110)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 36))
                .foregroundColor(Color.dFg3)
            Text("Nothing saved yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text("Bookmark films to watch later.")
                .font(.system(size: 13))
                .foregroundColor(Color.dFg3)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
}

// MARK: - Watchlist row

private struct WatchlistRow: View {
    var movie: Movie
    var isLast: Bool
    var action: () -> Void
    var onRemove: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                PosterArt(movie: movie, width: 72)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
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

                    Text([String(movie.year), movie.runtime, movie.genre]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · "))
                        .font(.system(size: 12))
                        .foregroundColor(Color.dFg3)
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Remove from Watchlist", systemImage: "bookmark.slash")
            }
        }

        if !isLast {
            Divider()
                .background(Color.dLine)
        }
    }
}
