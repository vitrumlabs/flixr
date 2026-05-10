import SwiftUI

// MARK: - Per-tab navigation state

private enum DiscoverNav: Equatable {
    case swipe, search
    case detail(Movie)
}

private enum WatchlistNav: Equatable {
    case list
    case detail(Movie)
}

// MARK: - Discovery flow — custom tab bar (pill + profile circle)

struct DiscoveryFlowView: View {
    @State private var activeTab: DiscoverTab = .discover
    @State private var discoverNav: DiscoverNav = .swipe
    @State private var watchlistNav: WatchlistNav = .list
    @State private var showFilters = false

    private var showsTabBar: Bool {
        switch activeTab {
        case .discover:  return discoverNav == .swipe
        case .watchlist: return watchlistNav == .list
        case .profile:   return true
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch activeTab {
                case .discover:  discoverTab
                case .watchlist: watchlistTab
                case .profile:   ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar {
                DiscoveryTabBar(active: activeTab) { tab in
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                }
                .padding(.bottom, 4)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showsTabBar)
        .preferredColorScheme(.dark)
    }

    // MARK: Discover tab

    @ViewBuilder
    private var discoverTab: some View {
        ZStack {
            switch discoverNav {
            case .swipe:
                DiscoverSwipeScreen(
                    onOpenFilters: { withAnimation { showFilters = true } },
                    onOpenDetail: { movie in withAnimation { discoverNav = .detail(movie) } },
                    onSearch: { withAnimation { discoverNav = .search } }
                )

            case .search:
                DiscoverySearchView(
                    onClose: { withAnimation { discoverNav = .swipe } },
                    onOpenDetail: { movie in withAnimation { discoverNav = .detail(movie) } }
                )

            case .detail(let movie):
                MovieDetailView(movie: movie, onClose: { withAnimation { discoverNav = .swipe } })
            }

            if showFilters {
                DiscoveryFiltersSheet(onClose: { withAnimation { showFilters = false } })
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: discoverNav)
        .animation(.easeInOut(duration: 0.25), value: showFilters)
    }

    // MARK: Watchlist tab

    @ViewBuilder
    private var watchlistTab: some View {
        ZStack {
            switch watchlistNav {
            case .list:
                WatchlistView(onOpenDetail: { movie in withAnimation { watchlistNav = .detail(movie) } })

            case .detail(let movie):
                MovieDetailView(movie: movie, onClose: { withAnimation { watchlistNav = .list } })
            }
        }
        .animation(.easeInOut(duration: 0.22), value: watchlistNav)
    }
}
