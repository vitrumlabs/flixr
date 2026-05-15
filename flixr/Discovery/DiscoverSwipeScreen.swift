import SwiftUI
import GoogleMobileAds

// MARK: - Deck item

private enum DeckItem: Identifiable {
    case movie(Movie)
    case ad(id: String)

    var id: String {
        switch self {
        case .movie(let m): return m.id
        case .ad(let id): return id
        }
    }
}

// MARK: - Screen 18: Discover · Swipe

struct DiscoverSwipeScreen: View {
    var filters: MovieFilters
    var onOpenFilters: () -> Void
    var onOpenProfile: () -> Void
    var onOpenDetail: (Movie) -> Void
    var onShuffle: () -> Void

    @Environment(UserLibrary.self) private var library

    @State private var movies: [Movie] = []
    @State private var deckIndex = 0
    @State private var isLoading = true
    @State private var fetchError = false
    @State private var cardFlyDirection: CGFloat? = nil
    @State private var shuffleTrigger = 0
    @State private var adLoader = NativeAdLoader()

    // Interleaves an ad slot after every 8th movie
    private var deck: [DeckItem] {
        var result: [DeckItem] = []
        for (i, movie) in movies.enumerated() {
            result.append(.movie(movie))
            if (i + 1) % 8 == 0 {
                result.append(.ad(id: "ad-slot-\(i)"))
            }
        }
        return result
    }

    private var currentDeck: [DeckItem] { Array(deck.dropFirst(deckIndex)) }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "14070a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                DiscoveryTopBar(onOpenProfile: onOpenProfile)
                    .padding(.top, 4)

                Spacer().frame(height: 16)

                GeometryReader { geo in
                    Group {
                        if isLoading {
                            loadingCard(width: geo.size.width - 28, maxHeight: geo.size.height)
                        } else if fetchError || movies.isEmpty {
                            errorCard(width: geo.size.width - 28, maxHeight: geo.size.height)
                        } else if currentDeck.isEmpty {
                            doneCard(width: geo.size.width - 28, maxHeight: geo.size.height)
                        } else {
                            CardStackView(
                                deck: currentDeck,
                                adLoader: adLoader,
                                width: geo.size.width - 28,
                                availableHeight: geo.size.height,
                                flyDirection: $cardFlyDirection,
                                onLike: { item in
                                    advance()
                                    if case .movie(let movie) = item {
                                        Task { await library.like(movie) }
                                    }
                                },
                                onSkip: { item in
                                    advance()
                                    if case .movie(let movie) = item {
                                        Task { await library.skip(movie) }
                                    }
                                },
                                onTap: { onOpenDetail($0) }
                            )
                            .padding(.horizontal, 14)
                        }
                    }
                }

                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 16) {
                        ActionButton(kind: .skip, size: 84) {
                            guard !currentDeck.isEmpty else { return }
                            cardFlyDirection = -1
                        }
                        .disabled(currentDeck.isEmpty || isLoading || cardFlyDirection != nil)

                        Button(action: onOpenFilters) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                        }
                        .glassEffect(.regular.interactive(), in: .circle)
                        .accessibilityLabel("Open Filters")

                        Button(action: { shuffleTrigger += 1; onShuffle() }) {
                            Image(systemName: "shuffle")
                                .symbolEffect(.bounce, value: shuffleTrigger)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                        }
                        .glassEffect(.regular.interactive(), in: .circle)
                        .accessibilityLabel("Shuffle")
                        .sensoryFeedback(.impact(weight: .medium), trigger: shuffleTrigger)

                        ActionButton(kind: .like, size: 84) {
                            guard !currentDeck.isEmpty else { return }
                            cardFlyDirection = 1
                        }
                        .disabled(currentDeck.isEmpty || isLoading || cardFlyDirection != nil)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadMovies() }
        .onChange(of: filters) { _, _ in
            cardFlyDirection = nil
            Task { await loadMovies() }
        }
    }

    // MARK: - Deck management

    private func advance() {
        let wasAd: Bool
        if let front = currentDeck.first, case .ad = front { wasAd = true } else { wasAd = false }

        // Include any unloaded ad skip in the same animation block to prevent a
        // visible jump between the outgoing card and the next movie.
        withAnimation(.easeOut(duration: 0.2)) {
            deckIndex += 1
            while let front = Array(deck.dropFirst(deckIndex)).first,
                  case .ad = front, adLoader.ad == nil {
                deckIndex += 1
            }
        }

        if wasAd { adLoader.loadNext() }

        let moviesLeft = currentDeck.filter { if case .movie = $0 { return true }; return false }.count
        if moviesLeft < 5 { Task { await loadMore() } }
    }

    private func loadMovies() async {
        isLoading = true
        fetchError = false
        deckIndex = 0
        adLoader.loadNext()
        do {
            movies = filters.isActive
                ? try await MovieService.shared.discover(filters: filters, page: 1)
                : try await MovieService.shared.fetchPopular(page: 1)
        } catch {
            fetchError = true
        }
        isLoading = false
    }

    private func loadMore() async {
        let nextPage = (movies.count / 20) + 1
        if filters.isActive {
            guard let more = try? await MovieService.shared.discover(filters: filters, page: nextPage) else { return }
            movies.append(contentsOf: more.filter { !movies.map(\.id).contains($0.id) })
        } else {
            guard let more = try? await MovieService.shared.fetchPopular(page: nextPage) else { return }
            movies.append(contentsOf: more.filter { !movies.map(\.id).contains($0.id) })
        }
    }

    // MARK: - State cards

    private func loadingCard(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white)
            Text("Finding films for you…")
                .font(.system(size: 15))
                .foregroundColor(.dFg3)
        }
        .frame(width: width, height: min(width / 0.66, maxHeight))
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func errorCard(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundColor(.dFg3)
            Text("Couldn't load films")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Button("Try again") { Task { await loadMovies() } }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.flxRed)
                .frame(minWidth: 44, minHeight: 44)
        }
        .frame(width: width, height: min(width / 0.66, maxHeight))
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func doneCard(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(.dFg3)
            Text("You've seen everything!")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Button("Load more") { Task { await loadMore() } }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.flxRed)
                .frame(minWidth: 44, minHeight: 44)
        }
        .frame(width: width, height: min(width / 0.66, maxHeight))
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Card stack

private struct CardStackView: View {
    var deck: [DeckItem]
    var adLoader: NativeAdLoader
    var width: CGFloat
    var availableHeight: CGFloat
    @Binding var flyDirection: CGFloat?
    var onLike: (DeckItem) -> Void
    var onSkip: (DeckItem) -> Void
    var onTap: (Movie) -> Void

    @State private var dragProgress: CGFloat = 0

    private var cardHeight: CGFloat { min(width / 0.66, availableHeight) }

    var body: some View {
        ZStack {
            ForEach(Array(deck.prefix(3).enumerated().reversed()), id: \.element.id) { depth, item in
                let isFront = depth == 0
                let p = Double(min(1, abs(dragProgress)))
                let baseScale = 1.0 - Double(depth) * 0.04
                let nextScale = depth > 0 ? 1.0 - Double(depth - 1) * 0.04 : 1.0
                let scale = isFront ? 1.0 : baseScale + (nextScale - baseScale) * p
                let baseTy = Double(depth) * 10.0
                let nextTy = depth > 0 ? Double(depth - 1) * 10.0 : 0.0
                let ty = isFront ? 0.0 : baseTy + (nextTy - baseTy) * p

                cardView(for: item, isFront: isFront)
                    .scaleEffect(scale)
                    .offset(y: ty)
                    .zIndex(Double(3 - depth))
            }
        }
        // Fixed frame prevents the ZStack from expanding its hit-testing area
        // beyond the visible card bounds.
        .frame(width: width, height: cardHeight)
    }

    @ViewBuilder
    private func cardView(for item: DeckItem, isFront: Bool) -> some View {
        switch item {
        case .movie(let movie):
            MovieCardView(
                movie: movie,
                isFront: isFront,
                width: width,
                availableHeight: availableHeight,
                dragProgress: isFront ? $dragProgress : .constant(0),
                flyDirection: isFront ? $flyDirection : .constant(nil),
                onLike: { onLike(item) },
                onSkip: { onSkip(item) },
                onTap: { onTap(movie) }
            )
        case .ad:
            if isFront, let nativeAd = adLoader.ad {
                AdCardView(
                    nativeAd: nativeAd,
                    width: width,
                    availableHeight: availableHeight,
                    dragProgress: $dragProgress,
                    flyDirection: $flyDirection,
                    onDismiss: { onSkip(item) }
                )
            } else {
                // Placeholder shown in positions 2 & 3 of the stack, or while ad loads
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: width, height: cardHeight)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Ad card (same swipe mechanics as MovieCardView, no LIKE/SKIP stamps)

private struct AdCardView: View {
    let nativeAd: NativeAd
    let width: CGFloat
    let availableHeight: CGFloat
    @Binding var dragProgress: CGFloat
    @Binding var flyDirection: CGFloat?
    var onDismiss: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var dragY: CGFloat = 0

    private var height: CGFloat { min(width / 0.66, availableHeight) }
    private var rotation: Double { Double(dragX) * 0.05 }

    var body: some View {
        NativeAdCardView(nativeAd: nativeAd, width: width, height: height)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.7), radius: 24, y: 12)
            .rotationEffect(.degrees(rotation))
            .offset(x: dragX, y: dragY * 0.4)
            .gesture(
                DragGesture()
                    .onChanged { v in
                        dragX = v.translation.width
                        dragY = v.translation.height
                        dragProgress = dragX / 150
                    }
                    .onEnded { v in
                        let overThreshold = abs(v.translation.width) > 90
                            || abs(v.predictedEndTranslation.width) > 200
                        if overThreshold {
                            flyOff(toward: v.translation.width > 0 ? 700 : -700)
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                dragX = 0; dragY = 0; dragProgress = 0
                            }
                        }
                    }
            )
            .onChange(of: flyDirection) { _, direction in
                guard let direction else { return }
                flyOff(toward: direction > 0 ? 700 : -700, isExternalTrigger: true)
            }
            .transition(.identity)
    }

    private func flyOff(toward target: CGFloat, isExternalTrigger: Bool = false) {
        withAnimation(.easeOut(duration: 0.28)) {
            dragX = target
            dragProgress = target > 0 ? 1 : -1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if isExternalTrigger { flyDirection = nil }
            onDismiss()
        }
    }
}

// MARK: - Individual movie card

private struct MovieCardView: View {
    var movie: Movie
    var isFront: Bool
    var width: CGFloat
    var availableHeight: CGFloat
    @Binding var dragProgress: CGFloat
    @Binding var flyDirection: CGFloat?
    var onLike: () -> Void
    var onSkip: () -> Void
    var onTap: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var dragY: CGFloat = 0

    private var height: CGFloat { min(width / 0.66, availableHeight) }
    private var rotation: Double { Double(dragX) * 0.05 }
    private var likeOpacity: Double { max(0, min(1, Double(dragX) / 100)) }
    private var skipOpacity: Double { max(0, min(1, Double(-dragX) / 100)) }

    var body: some View {
        ZStack(alignment: .bottom) {
            BackdropArt(movie: movie, aspectRatio: 0.66)
                .frame(width: width, height: height)

            LinearGradient(
                colors: [.clear, .black.opacity(0.55), .black.opacity(0.92)],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: .bottom
            )
            .frame(height: height * 0.62)

            // Top chips
            HStack(spacing: 6) {
                MetaChip(text: "\(String(format: "%.1f", movie.rating))", isRating: true)
                if !movie.cert.isEmpty { MetaChip(text: movie.cert) }
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 14).padding(.horizontal, 14)

            // LIKE stamp
            Text("LIKE")
                .font(.system(size: 28, weight: .heavy, design: .default).width(.condensed))
                .tracking(1.2).foregroundColor(Color(hex: "2BD17E"))
                .padding(.vertical, 8).padding(.horizontal, 18)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "2BD17E"), lineWidth: 3))
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 32).padding(.leading, 28)
                .opacity(likeOpacity)
                .allowsHitTesting(false)

            // SKIP stamp
            Text("SKIP")
                .font(.system(size: 28, weight: .heavy, design: .default).width(.condensed))
                .tracking(1.2).foregroundColor(.flxRed)
                .padding(.vertical, 8).padding(.horizontal, 18)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.flxRed, lineWidth: 3))
                .rotationEffect(.degrees(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 32).padding(.trailing, 28)
                .opacity(skipOpacity)
                .allowsHitTesting(false)

            // Meta block
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.flxDisplay(34)).tracking(-0.6)
                    .foregroundColor(.white).shadow(color: .black.opacity(0.6), radius: 6, y: 1)

                HStack(spacing: 0) {
                    Text(String(movie.year)).foregroundColor(Color.dFg2)
                    if !movie.genre.isEmpty {
                        DotSep()
                        Text(movie.genre).foregroundColor(.white).fontWeight(.semibold)
                    }
                }
                .font(.system(size: 13))
            }
            .padding(.horizontal, 18).padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        // Restrict tap hit area to the visible rounded card shape only.
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 24, y: 12)
        .rotationEffect(.degrees(rotation))
        .offset(x: dragX, y: dragY * 0.4)
        // No implicit animation on dragX — explicit withAnimation blocks handle
        // snap-back and fly-off so there's no conflict causing erratic motion.
        .gesture(
            isFront
            ? DragGesture()
                .onChanged { v in
                    dragX = v.translation.width
                    dragY = v.translation.height
                    dragProgress = dragX / 150
                }
                .onEnded { v in
                    let overThreshold = abs(v.translation.width) > 90
                        || abs(v.predictedEndTranslation.width) > 200
                    if overThreshold {
                        flyOff(toward: v.translation.width > 0 ? 700 : -700)
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            dragX = 0; dragY = 0; dragProgress = 0
                        }
                    }
                }
            : nil
        )
        .onTapGesture { if abs(dragX) < 6 { onTap() } }
        .allowsHitTesting(isFront)
        .onChange(of: flyDirection) { _, direction in
            guard let direction else { return }
            flyOff(toward: direction > 0 ? 700 : -700, isExternalTrigger: true)
        }
        .transition(.identity)
    }

    private func flyOff(toward target: CGFloat, isExternalTrigger: Bool = false) {
        let liked = target > 0
        withAnimation(.easeOut(duration: 0.28)) {
            dragX = target
            dragProgress = liked ? 1 : -1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            // Reset the external trigger before firing the callback so the
            // parent's disabled state lifts and the next card is ready.
            if isExternalTrigger { flyDirection = nil }
            if liked { onLike() } else { onSkip() }
        }
    }
}

// MARK: - Helpers

private struct MetaChip: View {
    var text: String
    var isRating = false

    var body: some View {
        HStack(spacing: 5) {
            if isRating {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            Text(text).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
        }
        .padding(.vertical, 5).padding(.horizontal, 10)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 4)
        .compositingGroup()
    }
}

struct DotSep: View {
    var body: some View {
        Circle().fill(Color.dFg3).frame(width: 3, height: 3).padding(.horizontal, 10)
    }
}
