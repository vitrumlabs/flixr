import SwiftUI

// MARK: - Sample prompts

private let samplePrompts = [
    "Something that'll make me cry",
    "Funny and light, nothing heavy",
    "Keep me on the edge of my seat",
    "A feel-good film for a rainy day",
    "Epic and adventurous",
    "Dark and thought-provoking",
    "Late night, can't sleep vibes",
    "Comfort rewatch energy",
]

// MARK: - Screen: Mood

struct MoodView: View {
    var onOpenDetail: (Movie) -> Void

    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var phase: Phase = .idle
    @FocusState private var inputFocused: Bool

    private enum Phase { case idle, loading, done, error }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

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

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mood")
                            .font(.flxDisplay(32))
                            .foregroundColor(.white)
                        Text("What are you in the mood for?")
                            .font(.system(size: 14))
                            .foregroundColor(Color.dFg3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                    // Prompt chips
                    ChipWrap(items: samplePrompts, spacing: 8) { prompt in
                        Button(action: { selectPrompt(prompt) }) {
                            Text(prompt)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(query == prompt ? .white : Color.dFg2)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    query == prompt
                                        ? Color.flxRed.opacity(0.25)
                                        : Color.white.opacity(0.06)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(
                                        query == prompt
                                            ? Color.flxRed.opacity(0.6)
                                            : Color.dLine,
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Text input + search button
                    HStack(spacing: 10) {
                        TextField("", text: $query, prompt:
                            Text("or describe your mood…")
                                .foregroundColor(Color.dFg3)
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .focused($inputFocused)
                        .submitLabel(.search)
                        .onSubmit { runSearch() }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.dLine, lineWidth: 1)
                        )

                        Button(action: runSearch) {
                            Group {
                                if phase == .loading {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(query.trimmingCharacters(in: .whitespaces).isEmpty ? Color.flxRed.opacity(0.35) : Color.flxRed)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || phase == .loading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Results
                    switch phase {
                    case .idle:
                        EmptyView()

                    case .loading:
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                FlxSpinner()
                                Text("Finding films…")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.dFg3)
                            }
                            Spacer()
                        }
                        .padding(.top, 60)

                    case .error:
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.dFg3)
                                Text("Couldn't find films right now.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.dFg3)
                                Button("Try again") { runSearch() }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.flxRed)
                            }
                            Spacer()
                        }
                        .padding(.top, 60)

                    case .done:
                        if results.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "film")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color.dFg3)
                                    Text("No matches found.\nTry a different mood.")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.dFg3)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(results) { movie in
                                    MoodResultCard(movie: movie) {
                                        onOpenDetail(movie)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer().frame(height: 110)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .preferredColorScheme(.dark)
    }

    private func selectPrompt(_ prompt: String) {
        query = prompt
        inputFocused = false
        runSearch()
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, phase != .loading else { return }
        inputFocused = false
        phase = .loading
        Task {
            do {
                let movies = try await MovieService.shared.moodSearch(query: trimmed)
                results = movies
                phase = .done
            } catch {
                phase = .error
            }
        }
    }
}

// MARK: - Result card

private struct MoodResultCard: View {
    let movie: Movie
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    PosterArt(movie: movie, width: geo.size.width)
                        .frame(width: geo.size.width, height: geo.size.width * 1.5)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .aspectRatio(2/3, contentMode: .fit)

                Text(movie.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chip wrapping layout

private struct ChipWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowX: CGFloat = 0
        var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if rowX + size.width > maxW, rowX > 0 {
                height += rowH + spacing
                rowX = 0; rowH = 0
            }
            rowX += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: maxW, height: height + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX; rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
