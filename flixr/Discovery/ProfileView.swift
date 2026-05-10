import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Screen 23: Profile

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(UserLibrary.self) private var library

    @State private var skippedCount = 0
    @State private var isFlixrPlus  = false

    private var user: FirebaseAuth.User? { auth.user }

    private var displayName: String {
        if let name = user?.displayName, !name.isEmpty { return name }
        return user?.email?.components(separatedBy: "@").first ?? "User"
    }

    private var initials: String {
        let words = displayName.split(separator: " ").prefix(2)
        return words.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    private var memberSince: String {
        guard let date = user?.metadata.creationDate else { return "" }
        return "Member since \(Calendar.current.component(.year, from: date))"
    }

    private var stats: [(String, String)] {[
        ("Swiped",    (library.liked.count + skippedCount).formatted()),
        ("Liked",     library.liked.count.formatted()),
        ("Watchlist", library.watchlist.count.formatted()),
    ]}

    private let settingRows: [(label: String, sub: String, icon: String)] = [
        ("Filters & Preferences", "Genres, mood, decade",  "slider.horizontal.3"),
        ("Streaming services",    "Choose your platforms", "play.tv"),
        ("Subscription",          "Manage your plan",      "star"),
        ("Notifications",         "New matches · Trailers","bell"),
        ("Help & feedback",       "Get in touch",          "questionmark.circle"),
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "14070a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    Text("Profile")
                        .font(.flxDisplay(28))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 12)

                    // User info row
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "3a1556"), Color(hex: "1a0a30")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Circle()
                                .strokeBorder(Color.flxRed.opacity(0.55), lineWidth: 1.5)
                                .shadow(color: Color.flxRed.opacity(0.25), radius: 12)

                            if let photoURL = user?.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Text(initials).font(.flxDisplay(28)).foregroundColor(.white)
                                }
                                .clipShape(Circle())
                            } else {
                                Text(initials).font(.flxDisplay(28)).foregroundColor(.white)
                            }
                        }
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.flxDisplay(22))
                                .foregroundColor(.white)

                            Group {
                                if let email = user?.email, !memberSince.isEmpty {
                                    Text("\(email) · \(memberSince)")
                                } else if let email = user?.email {
                                    Text(email)
                                } else if !memberSince.isEmpty {
                                    Text(memberSince)
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color.dFg3)

                            if isFlixrPlus {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color(hex: "FFD700"))
                                    Text("Flixr Plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(0.4)
                                        .textCase(.uppercase)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.flxRed.opacity(0.18))
                                .clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(Color.flxRed.opacity(0.45), lineWidth: 1))
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // Stats grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(stats, id: \.0) { stat in
                            VStack(spacing: 2) {
                                Text(stat.1)
                                    .font(.flxDisplay(22))
                                    .foregroundColor(.white)
                                Text(stat.0)
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.8)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color.dFg3)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.dLine, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // Taste card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your taste")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color.dFg3)

                        if library.topGenres.isEmpty {
                            Text("Keep swiping to build your taste profile.")
                                .font(.system(size: 14))
                                .foregroundColor(Color.dFg3)
                                .padding(.vertical, 4)
                        } else {
                            GenreChips(genres: library.topGenres)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                    // Settings rows
                    VStack(spacing: 0) {
                        ForEach(Array(settingRows.enumerated()), id: \.element.label) { i, row in
                            Button(action: {}) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.flxRed.opacity(0.12))
                                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.flxRed.opacity(0.25), lineWidth: 1))
                                        Image(systemName: row.icon)
                                            .font(.system(size: 15))
                                            .foregroundColor(.flxRed)
                                    }
                                    .frame(width: 36, height: 36)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(row.label)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(row.sub)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.dFg3)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.dFg3)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            if i < settingRows.count - 1 {
                                Divider()
                                    .background(Color.dLine)
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Sign out
                    Button(action: { auth.signOut() }) {
                        Text("Sign out")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.dFg3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.bottom, 110)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await fetchStats() }
    }

    private func fetchStats() async {
        guard let uid = user?.uid else { return }
        guard let data = try? await Firestore.firestore()
            .collection("users").document(uid).getDocument().data()
        else { return }
        skippedCount = (data["skipped"] as? [Any])?.count ?? 0
        isFlixrPlus  = data["isFlixrPlus"] as? Bool ?? false
    }
}

// MARK: - Genre chips (wrapping layout)

private struct GenreChips: View {
    var genres: [String]

    var body: some View {
        // Wrapping rows built from measured items
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.flxRed.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.flxRed.opacity(0.45), lineWidth: 1))
                    }
                }
            }
        }
    }

    // Approximate wrapping: max 3 genres per row
    private var rows: [[String]] {
        stride(from: 0, to: genres.count, by: 3).map {
            Array(genres[$0..<min($0 + 3, genres.count)])
        }
    }
}
