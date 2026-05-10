import SwiftUI

// MARK: - Screen 18: Discover · Swipe

struct DiscoverSwipeScreen: View {
    var onOpenFilters: () -> Void
    var onOpenDetail: (Movie) -> Void
    var onSearch: () -> Void

    @State private var cardIndex = 0

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

                // Card stack — takes all remaining space; height is capped inside
                GeometryReader { geo in
                    CardStackView(
                        startIndex: cardIndex,
                        width: geo.size.width - 28,
                        availableHeight: geo.size.height,
                        onSwipe: { cardIndex = ($0 + 1) % movieCatalog.count },
                        onTap: { onOpenDetail(movieCatalog[$0 % movieCatalog.count]) }
                    )
                    .padding(.horizontal, 14)
                }

                // Action buttons
                HStack(spacing: 28) {
                    ActionButton(kind: .skip, size: 72) {
                        cardIndex = (cardIndex + 1) % movieCatalog.count
                    }

                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                    }
                    .glassEffect(in: Circle())

                    ActionButton(kind: .like, size: 72) {
                        cardIndex = (cardIndex + 1) % movieCatalog.count
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 116)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Card stack

private struct CardStackView: View {
    var startIndex: Int
    var width: CGFloat
    var availableHeight: CGFloat
    var onSwipe: (Int) -> Void
    var onTap: (Int) -> Void

    // Shared drag progress so back cards can react smoothly to front-card drags
    @State private var dragProgress: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach((0..<3).reversed(), id: \.self) { depth in
                let movieIndex = (startIndex + depth) % movieCatalog.count
                let isFront = depth == 0

                // Lerp back-card scale/offset toward next depth as front card is dragged
                let p = Double(min(1, abs(dragProgress)))
                let baseScale = 1.0 - Double(depth) * 0.04
                let nextScale = depth > 0 ? 1.0 - Double(depth - 1) * 0.04 : 1.0
                let scale = isFront ? 1.0 : baseScale + (nextScale - baseScale) * p

                let baseTy = Double(depth) * 10.0
                let nextTy = depth > 0 ? Double(depth - 1) * 10.0 : 0.0
                let ty = isFront ? 0.0 : baseTy + (nextTy - baseTy) * p

                MovieCardView(
                    movie: movieCatalog[movieIndex],
                    isFront: isFront,
                    width: width,
                    availableHeight: availableHeight,
                    dragProgress: isFront ? $dragProgress : .constant(0),
                    onSwipe: { onSwipe(startIndex) },
                    onTap: { onTap(movieIndex) }
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
    var onSwipe: () -> Void
    var onTap: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var dragY: CGFloat = 0
    @State private var isDragging = false

    // Cap height to available space so the card never overflows into the button row
    private var height: CGFloat { min(width / 0.66, availableHeight) }
    private var rotation: Double { Double(dragX) * 0.05 }
    private var likeOpacity: Double { max(0, min(1, Double(dragX) / 100)) }
    private var skipOpacity: Double { max(0, min(1, Double(-dragX) / 100)) }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cinematic backdrop stretched to fill
            BackdropArt(movie: movie, aspectRatio: 0.66)
                .frame(width: width, height: height)

            // Bottom gradient overlay
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
                MetaChip(text: movie.cert)
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 14)
            .padding(.horizontal, 14)

            // LIKE stamp
            Text("LIKE")
                .font(.system(size: 28, weight: .heavy, design: .default).width(.condensed))
                .tracking(1.2)
                .foregroundColor(Color(hex: "2BD17E"))
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(hex: "2BD17E"), lineWidth: 3)
                )
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 32).padding(.leading, 28)
                .opacity(likeOpacity)

            // SKIP stamp
            Text("SKIP")
                .font(.system(size: 28, weight: .heavy, design: .default).width(.condensed))
                .tracking(1.2)
                .foregroundColor(.flxRed)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.flxRed, lineWidth: 3)
                )
                .rotationEffect(.degrees(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 32).padding(.trailing, 28)
                .opacity(skipOpacity)

            // Meta block (bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.flxDisplay(34))
                    .tracking(-0.6)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 6, y: 1)

                HStack(spacing: 0) {
                    Text(String(movie.year))
                        .foregroundColor(Color.dFg2)
                    DotSep()
                    Text(movie.runtime)
                        .foregroundColor(Color.dFg2)
                    DotSep()
                    Text(movie.genre)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 13))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
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
                    dragProgress = dragX / 150   // drive back-card animation
                }
                .onEnded { v in
                    isDragging = false
                    let threshold = abs(v.translation.width) > 90
                        || abs(v.predictedEndTranslation.width) > 200
                    if threshold {
                        let direction: CGFloat = v.translation.width > 0 ? 700 : -700
                        withAnimation(.easeOut(duration: 0.28)) { dragX = direction }
                        // Wait until card is fully off-screen before cycling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                            dragX = 0
                            dragY = 0
                            dragProgress = 0
                            onSwipe()
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            dragX = 0
                            dragY = 0
                            dragProgress = 0
                        }
                    }
                }
            : nil
        )
        .onTapGesture {
            if abs(dragX) < 6 { onTap() }
        }
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
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 4)
        .compositingGroup()
    }
}

struct DotSep: View {
    var body: some View {
        Circle()
            .fill(Color.dFg3)
            .frame(width: 3, height: 3)
            .padding(.horizontal, 10)
    }
}
