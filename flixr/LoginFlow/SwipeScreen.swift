import SwiftUI

// Movie cards for taste-test screen
private struct MovieCard {
    let title: String
    let year: Int
    let genre: String
    let gradientTop: Color
    let gradientBottom: Color
}

private let deck: [MovieCard] = [
    MovieCard(title: "Interstellar",  year: 2014, genre: "Sci-Fi · Drama",    gradientTop: Color(hex: "1c2330"), gradientBottom: Color(hex: "0a0d12")),
    MovieCard(title: "Dune",          year: 2021, genre: "Sci-Fi · Epic",     gradientTop: Color(hex: "3a2415"), gradientBottom: Color(hex: "0e0805")),
    MovieCard(title: "The Batman",    year: 2022, genre: "Action · Noir",     gradientTop: Color(hex: "2c0d10"), gradientBottom: Color(hex: "070304")),
    MovieCard(title: "Oppenheimer",   year: 2023, genre: "Drama · History",   gradientTop: Color(hex: "3a2a1a"), gradientBottom: Color(hex: "0c0805")),
    MovieCard(title: "Arrival",       year: 2016, genre: "Sci-Fi · Drama",    gradientTop: Color(hex: "1a2a30"), gradientBottom: Color(hex: "050a0d")),
]

struct SwipeScreen: View {
    var go: (LoginScreen) -> Void

    @State private var index = 0
    @State private var dragOffset: CGSize = .zero

    private var remaining: [MovieCard] { Array(deck.dropFirst(index)) }
    private var isDone: Bool { index >= deck.count }

    var body: some View {
        ZStack {
            // Vignette background (no poster plate on swipe screen)
            LinearGradient(
                colors: [Color(hex: "1a0a0c"), Color(hex: "0a0506"), .black],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 4) {
                    ForEach(0..<deck.count, id: \.self) { i in
                        Capsule()
                            .fill(i < index ? Color.flxRed : Color.white.opacity(0.12))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 22)

                // Header
                VStack(spacing: 4) {
                    Text("Step \(min(index + 1, deck.count)) of \(deck.count)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(.flxRed)

                    VStack(spacing: 0) {
                        Text("Pick a few you'd")
                            .font(.flxDisplay(28))
                            .foregroundColor(.white)
                        Text("actually watch.")
                            .font(.flxDisplay(28))
                            .foregroundColor(.flxRed)
                    }
                    .multilineTextAlignment(.center)

                    Text("This shapes your recommendations.")
                        .font(.system(size: 14))
                        .foregroundColor(.fg3)
                        .padding(.top, 4)
                }
                .padding(.bottom, 14)

                // Card stack
                ZStack {
                    if isDone {
                        VStack(spacing: 12) {
                            LoadingDots()
                            Text("Tuning your feed…").foregroundColor(.fg2).font(.system(size: 15))
                        }
                        .frame(height: 420)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { go(.swipeLoading) }
                        }
                    } else {
                        ForEach(Array(remaining.prefix(3).enumerated().reversed()), id: \.offset) { depth, card in
                            let isFront = depth == 0
                            let scale = 1.0 - Double(depth) * 0.04
                            let ty = Double(depth) * 12

                            CardView(card: card, dragOffset: isFront ? dragOffset : .zero)
                                .frame(width: UIScreen.main.bounds.width - 48, height: 420)
                                .scaleEffect(scale)
                                .offset(y: ty)
                                .opacity(1 - Double(depth) * 0.18)
                                .zIndex(Double(3 - depth))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
                                .gesture(
                                    isFront
                                    ? DragGesture()
                                        .onChanged { dragOffset = $0.translation }
                                        .onEnded { val in
                                            withAnimation(.spring(response: 0.3)) {
                                                if abs(val.translation.width) > 80 {
                                                    advanceCard()
                                                } else {
                                                    dragOffset = .zero
                                                }
                                            }
                                        }
                                    : nil
                                )
                        }
                    }
                }
                .frame(height: 420)

                Spacer(minLength: 0)

                // Like / Skip buttons
                if !isDone {
                    HStack(spacing: 22) {
                        // Skip
                        Button(action: advanceCard) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.borderSubtle, lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        // Like
                        Button(action: advanceCard) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(Color.flxRed)
                                .clipShape(Circle())
                                .shadow(color: Color.flxRed.opacity(0.45), radius: 12, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.vertical, 14)

                    Button("Skip for now") { go(.done) }
                        .font(.system(size: 14))
                        .foregroundColor(.fg3)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
    }

    private func advanceCard() {
        withAnimation(.spring(response: 0.3)) {
            dragOffset = .zero
            index += 1
        }
    }
}

// MARK: - Movie poster card

private struct CardView: View {
    var card: MovieCard
    var dragOffset: CGSize

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: [card.gradientTop, card.gradientBottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.6), radius: 20, y: 8)

            // Title bar
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.flxDisplay(24))
                    .tracking(-0.4)
                    .foregroundColor(.white)
                Text("\(card.year) · \(card.genre)")
                    .font(.system(size: 13))
                    .foregroundColor(.fg2)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 22)

            // Movie title watermark (top-left)
            Text(card.title.uppercased())
                .font(.flxDisplay(card.title.count > 8 ? 18 : 22))
                .tracking(1.4)
                .foregroundColor(.white.opacity(0.85))
                .blendMode(.screen)
                .opacity(0.85)
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.04), lineWidth: 1))
        .rotationEffect(.degrees(dragOffset.width / 20))
        .offset(dragOffset)
    }
}
