import SwiftUI

struct MoodResultsView: View {
    let query: String
    let results: [Movie]
    var onBack: () -> Void
    var onOpenDetail: (Movie) -> Void

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "070a14"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Space reserved for floating back button
                    Spacer().frame(height: 64)

                    // Query header
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Matched to your mood")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.3)
                            .textCase(.uppercase)
                            .foregroundColor(Color.dFg3)
                        Text("\"\(query)\"")
                            .font(.flxDisplay(20))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    if results.isEmpty {
                        emptyState
                    } else {
                        resultsList
                    }

                    Spacer().frame(height: 40)
                }
            }
            .overlay(alignment: .topLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .glassEffect(.clear.interactive(), in: .circle)
                .accessibilityLabel("Back")
                .padding(.leading, 20)
                .padding(.top, 16)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "film")
                .font(.system(size: 32))
                .foregroundColor(Color.dFg3)
            Text("No matches found.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Try describing your mood differently.")
                .font(.system(size: 14))
                .foregroundColor(Color.dFg3)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: Results — hero card + list rows (content layer, no glass)

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero card — top match
            if let top = results.first {
                Button(action: { onOpenDetail(top) }) {
                    ZStack(alignment: .bottomLeading) {
                        GeometryReader { geo in
                            PosterArt(movie: top, width: geo.size.width)
                                .frame(width: geo.size.width, height: geo.size.width * 1.5)
                        }
                        .aspectRatio(2/3, contentMode: .fit)

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.88)],
                            startPoint: UnitPoint(x: 0.5, y: 0.45),
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top match")
                                .font(.system(size: 10.5, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(.flxRed)
                            Text(top.title)
                                .font(.flxDisplay(22))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            // Remaining results as list rows
            if results.count > 1 {
                VStack(spacing: 0) {
                    ForEach(
                        Array(results.dropFirst().prefix(11).enumerated()),
                        id: \.element.id
                    ) { i, movie in
                        Button(action: { onOpenDetail(movie) }) {
                            HStack(spacing: 12) {
                                PosterArt(movie: movie, width: 52)
                                    .frame(width: 52, height: 78)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(movie.title)
                                    .font(.flxDisplay(15))
                                    .foregroundColor(.white)
                                    .lineLimit(2)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.dFg3)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)

                        if i < min(results.count - 2, 10) {
                            Divider()
                                .background(Color.dLine)
                                .padding(.leading, 84)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}
