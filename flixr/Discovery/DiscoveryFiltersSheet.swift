import SwiftUI

// MARK: - Screen 20: Filters bottom sheet (overlay)

struct DiscoveryFiltersSheet: View {
    var onApply: (MovieFilters) -> Void
    var onClose: () -> Void

    @State private var selectedGenres: Set<String>
    @State private var selectedDecade: String?
    @State private var selectedSort: String
    @State private var minRating: Double
    @State private var selectedCertifications: Set<String>

    private let genres         = ["Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary", "Drama", "Fantasy", "History", "Horror", "Music", "Mystery", "Romance", "Sci-Fi", "Thriller", "War", "Western"]
    private let decades        = ["2020s", "2010s", "2000s", "90s", "80s", "Older"]
    private let sortLabels     = ["Popular", "Top Rated", "Newest", "Blockbusters"]
    private let certifications = ["G", "PG", "PG-13", "R", "NC-17"]

    init(initialFilters: MovieFilters, onApply: @escaping (MovieFilters) -> Void, onClose: @escaping () -> Void) {
        self.onApply = onApply
        self.onClose = onClose
        _selectedGenres        = State(initialValue: initialFilters.genres)
        _selectedDecade        = State(initialValue: initialFilters.decade)
        _selectedSort          = State(initialValue: initialFilters.sortBy)
        _minRating             = State(initialValue: initialFilters.minRating / 10)
        _selectedCertifications = State(initialValue: initialFilters.certifications)
    }

    private var currentFilters: MovieFilters {
        MovieFilters(genres: selectedGenres, decade: selectedDecade, sortBy: selectedSort,
                     minRating: minRating * 10, certifications: selectedCertifications)
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .blur(radius: 2)
                .onTapGesture { onClose() }

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 14)

                    // Title row
                    HStack {
                        Text("Filters")
                            .font(.flxDisplay(24))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Reset") {
                            selectedGenres = []
                            selectedDecade = nil
                            selectedSort = "Popular"
                            minRating = 0
                            selectedCertifications = []
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.flxRed)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            FilterSection(title: "Genre") {
                                FlexChips(items: genres) { genre in
                                    FilterChip(
                                        label: genre,
                                        isActive: selectedGenres.contains(genre),
                                        action: {
                                            if selectedGenres.contains(genre) { selectedGenres.remove(genre) }
                                            else { selectedGenres.insert(genre) }
                                        }
                                    )
                                }
                            }

                            FilterSection(title: "Decade") {
                                FlexChips(items: decades) { decade in
                                    FilterChip(label: decade, isActive: decade == selectedDecade) {
                                        selectedDecade = (selectedDecade == decade) ? nil : decade
                                    }
                                }
                            }

                            FilterSection(title: "Rating") {
                                FlexChips(items: certifications) { cert in
                                    FilterChip(
                                        label: cert,
                                        isActive: selectedCertifications.contains(cert),
                                        action: {
                                            if selectedCertifications.contains(cert) {
                                                selectedCertifications.remove(cert)
                                            } else {
                                                selectedCertifications.insert(cert)
                                            }
                                        }
                                    )
                                }
                            }

                            FilterSection(title: "Sort by") {
                                FlexChips(items: sortLabels) { label in
                                    FilterChip(label: label, isActive: label == selectedSort) {
                                        selectedSort = label
                                    }
                                }
                            }

                            FilterSection(title: "Min rating") {
                                RatingSlider(value: $minRating)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 22)
                    }
                    .containerRelativeFrame(.vertical) { h, _ in h * 0.56 }

                    // CTA
                    FlxButton(title: "Show results", variant: .primary) {
                        onApply(currentFilters)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                .background(
                    LinearGradient(
                        colors: [Color(hex: "161616"), Color(hex: "0a0a0a")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.dLine, lineWidth: 1)
                        .mask(Rectangle().padding(.bottom, -24))
                )
                .shadow(color: .black.opacity(0.6), radius: 20, y: -10)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Filter section wrapper

private struct FilterSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Color.dFg3)
            content()
        }
    }
}

// MARK: - Flex chip row (wrapping)

private struct FlexChips<Item: Hashable, ChipView: View>: View {
    var items: [Item]
    @ViewBuilder var chip: (Item) -> ChipView

    var body: some View {
        FlowLayoutInternal(spacing: 8, lineSpacing: 8) {
            ForEach(items, id: \.self) { item in chip(item) }
        }
    }
}

// MARK: - Rating slider

private struct RatingSlider: View {
    @Binding var value: Double

    private var displayRating: String {
        String(format: "%.1f+", value * 10)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(displayRating)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    Capsule()
                        .fill(Color.flxRed)
                        .frame(width: max(0, CGFloat(value) * geo.size.width), height: 4)
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                        .offset(x: max(0, CGFloat(value) * (geo.size.width - 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    value = max(0, min(1, Double(v.location.x) / Double(geo.size.width)))
                                }
                        )
                }
            }
            .frame(height: 28)
        }
    }
}

// MARK: - Internal flow layout (reused from search view)

private struct FlowLayoutInternal: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var x: CGFloat = 0; var y: CGFloat = 0; var lineH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 { y += lineH + lineSpacing; x = 0; lineH = 0 }
            lineH = max(lineH, size.height); x += size.width + spacing
        }
        return CGSize(width: maxWidth, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var lineH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            lineH = max(lineH, size.height); x += size.width + spacing
        }
    }
}
