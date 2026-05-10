import SwiftUI

// MARK: - Screen 18: Discover · Swipe

struct DiscoverSwipeScreen: View {
    var onOpenFilters: () -> Void
    var onOpenDetail: (Movie) -> Void
    var onSearch: () -> Void

    @Environment(UserLibrary.self) private var library

    @State private var movies: [Movie] = []
    @State private var cardIndex = 0
    @State private var isLoading = true
    @State private var fetchError = false

    private var currentDeck: [Movie] { Array(movies.dropFirst(cardIndex)) }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "14070a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                DiscoveryTopBar(onFilter: onOpenFilters)
                    .padding(.top, 4)

                Spacer().frame(height: 16)

                GeometryReader { geo in
                    Group {
                        if isLoading {
                            loadingCard(width: geo.size.width - 28)
                        } else if fetchError || movies.isEmpty {
                            errorCard(width: geo.size.width - 28)
                        } else if currentDeck.isEmpty {
                            doneCard(width: geo.size.width - 28)
                        } else {
                            CardStackView(
                                deck: currentDeck,
                                width: geo.size.width - 28,
                                availableHeight: geo.size.height,
                                onLike: { movie in
                                    advance()
                                    Task { await library.like(movie) }
                                },
                                onSkip: { movie in
                                    advance()
                                    Task { await library.skip(movie) }
                                },
                                onTap: { onOpenDetail($0) }
                            )
                            .padding(.horizontal, 14)
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 28) {
                    ActionButton(kind: .skip, size: 72) {
                        guard let movie = currentDeck.first else { return }
                        advance()
                        Task { await library.skip(movie) }
                    }
                    .disabled(currentDeck.isEmpty || isLoading)

                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                    }
                    .glassEffect(in: Circle())

                    ActionButton(kind: .like, size: 72) {
                        guard let movie = currentDeck.first else { return }
                        advance()
                        Task { await library.like(movie) }
                    }
                    .disabled(currentDeck.isEmpty || isLoading)
                }
                .padding(.top, 20)
                .padding(.bottom, 116)
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadMovies() }
    }

    private func advance() {
        withAnimation(.easeOut(duration: 0.2)) { cardIndex += 1 }
        // Pre-fetch next page when near the end
        if movies.count - cardIndex < 5 {
            Task { await loadMore() }
        }
    }

    private func loadMovies() async {
        isLoading = true
        fetchError = false
        do {
            movies = try await MovieService.shared.fetchPopular(page: 1)
        } catch {
            fetchError = true
        }
        isLoading = false
    }

    private func loadMore() async {
        let nextPage = (movies.count / 20) + 1
        guard let more = try? await MovieService.shared.fetchPopular(page: nextPage) else { return }
        movies.append(contentsOf: more.filter { !movies.map(\.id).contains($0.id) })
    }

    // MARK: - State cards

    private func loadingCard(width: CGFloat) -> some View {
        VStack(spacing: 16) {
            ProgressView().tint(.white)
            Text("Finding films for you…")
                .font(.system(size: 15))
                .foregroundColor(.dFg3)
        }
        .frame(width: width, height: width / 0.66)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func errorCard(width: CGFloat) -> some View {
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
        }
        .frame(width: width, height: width / 0.66)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func doneCard(width: CGFloat) -> some View {
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
        }
        .frame(width: width, height: width / 0.66)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Card stack

private struct CardStackView: View {
    var deck: [Movie]           // deck[0] is front card
    var width: CGFloat
    var availableHeight: CGFloat
    var onLike: (Movie) -> Void
    var onSkip: (Movie) -> Void
    var onTap: (Movie) -> Void

    @State private var dragProgress: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(Array(deck.prefix(3).enumerated().reversed()), id: \.element.id) { depth, movie in
                let isFront = depth == 0
                let p = Double(min(1, abs(dragProgress)))
                let baseScale = 1.0 - Double(depth) * 0.04
                let nextScale = depth > 0 ? 1.0 - Double(depth - 1) * 0.04 : 1.0
                let scale = isFront ? 1.0 : baseScale + (nextScale - baseScale) * p
                let baseTy = Double(depth) * 10.0
                let nextTy = depth > 0 ? Double(depth - 1) * 10.0 : 0.0
                let ty = isFront ? 0.0 : baseTy + (nextTy - baseTy) * p

                MovieCardView(
                    movie: movie,
                    isFront: isFront,
                    width: width,
                    availableHeight: availableHeight,
                    dragProgress: isFront ? $dragProgress : .constant(0),
                    onLike: { onLike(movie) },
                    onSkip: { onSkip(movie) },
                    onTap: { onTap(movie) }
                )
                .scaleEffect(scale)
                .offset(y: ty)
                .zIndex(Double(3 - depth))
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Individual movie card

private struct MovieCardView: View {
    var movie: Movie
    var isFront: Bool
    var width: CGFloat
    var availableHeight: CGFloat
    @Binding var dragProgress: CGFloat
    var onLike: () -> Void
    var onSkip: () -> Void
    var onTap: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @State private var isDragging = false

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
                MetaChip(text: movie.releaseDate)
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
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 24, y: 12)
        .rotationEffect(.degrees(rotation))
        .offset(x: dragX, y: dragY * 0.4)
        .animation(isDragging ? .none : .spring(response: 0.35, dampingFraction: 0.75), value: dragX)
        .gesture(
            isFront
            ? DragGesture()
                .onChanged { v in
                    isDragging = true
                    dragX = v.translation.width
                    dragY = v.translation.height
                    dragProgress = dragX / 150
                }
                .onEnded { v in
                    isDragging = false
                    let threshold = abs(v.translation.width) > 90
                        || abs(v.predictedEndTranslation.width) > 200
                    if threshold {
                        let direction: CGFloat = v.translation.width > 0 ? 700 : -700
                        let liked = direction > 0
                        withAnimation(.easeOut(duration: 0.28)) { dragX = direction }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                            dragX = 0; dragY = 0; dragProgress = 0
                            if liked { onLike() } else { onSkip() }
                        }
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
