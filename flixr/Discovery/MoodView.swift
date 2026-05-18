import SwiftUI

// MARK: - Mood presets

private let moodPresets: [String] = [
    "Hype me up",
    "Spaghetti western",
    "Something to cry to",
    "Space thriller",
    "Mind-bending thriller",
    "Cozy & warm",
    "I'm stressed, distract me",
    "Pirate adventure",
    "Dark & intense",
    "Need a good laugh",
]

// MARK: - Entry: owns input ↔ results navigation

struct MoodView: View {
    var onOpenDetail: (Movie) -> Void

    @State private var query = ""
    @State private var results: [Movie] = []
    @State private var showResults = false

    var body: some View {
        ZStack {
            MoodInputView(query: $query) { movies in
                results = movies
                withAnimation(.easeInOut(duration: 0.3)) { showResults = true }
            }

            if showResults {
                MoodResultsView(
                    query: query,
                    results: results,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.3)) { showResults = false }
                    },
                    onOpenDetail: onOpenDetail
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Input screen

private struct MoodInputView: View {
    @Binding var query: String
    var onSearch: ([Movie]) -> Void

    @State private var phase: Phase = .idle
    @FocusState private var inputFocused: Bool

    private enum Phase { case idle, loading, error }

    private let chipColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }
    private var canSearch: Bool { !trimmed.isEmpty && phase != .loading }

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's the\nmood tonight?")
                            .font(.flxDisplay(36))
                            .foregroundColor(.white)
                        Text("Tell us how you're feeling — we'll find\na few movies that fit.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.dFg3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    // Text area
                    HStack(alignment: .top) {
                        TextField(
                            "e.g. 'something feel-good to watch with a friend'",
                            text: $query,
                            axis: .vertical
                        )
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .tint(.flxRed)
                        .focused($inputFocused)
                        .lineLimit(4...)
                        .submitLabel(.search)
                        .onSubmit { runSearch() }
                        .accessibilityLabel("Describe your mood")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)

                        if !query.isEmpty {
                            Button(action: {
                                query = ""
                                phase = .idle
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.dFg3)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .padding(.top, 6)
                            .padding(.trailing, 4)
                        }
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                inputFocused ? Color.flxRed.opacity(0.8) : Color.dLine,
                                lineWidth: inputFocused ? 1.5 : 1
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // "Or pick a mood" label
                    Text("Or pick a mood")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(Color.dFg3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    // Preset chips — glass controls, shared sampling region
                    GlassEffectContainer(spacing: 10) {
                        LazyVGrid(columns: chipColumns, spacing: 10) {
                            ForEach(moodPresets, id: \.self) { preset in
                                let isSelected = query == preset
                                Button(action: {
                                    withAnimation(.bouncy) { query = preset }
                                    inputFocused = false
                                }) {
                                    Text(preset)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : Color.dFg2)
                                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                        .padding(.horizontal, 14)
                                }
                                .buttonStyle(.plain)
                                .glassEffect(
                                    (isSelected
                                        ? Glass.regular.tint(.flxRed)
                                        : .regular
                                    ).interactive(),
                                    in: Capsule()
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    if phase == .error {
                        Text("Couldn't find films right now. Try again.")
                            .font(.system(size: 13))
                            .foregroundColor(Color.flxRed.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // "Find my movie" CTA — inline, stays put when keyboard opens
                    Button(action: runSearch) {
                        HStack(spacing: 8) {
                            if phase == .loading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text("Find my movie")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canSearch
                                ? LinearGradient(
                                    colors: [Color(hex: "F11823"), Color(hex: "E50914"), Color(hex: "C8060F")],
                                    startPoint: .top, endPoint: .bottom)
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                                    startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
                    .disabled(!canSearch)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .preferredColorScheme(.dark)
    }

    private func runSearch() {
        guard canSearch else { return }
        inputFocused = false
        phase = .loading
        Task {
            do {
                let movies = try await MovieService.shared.moodSearch(query: trimmed)
                phase = .idle
                onSearch(movies)
            } catch {
                phase = .error
            }
        }
    }
}
