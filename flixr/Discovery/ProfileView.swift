import SwiftUI

// MARK: - Screen 23: Profile

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth

    private let stats: [(String, String)] = [
        ("Swiped",  "1,284"),
        ("Liked",   "312"),
        ("Watched", "112"),
    ]

    private let taste: [(String, Double)] = [
        ("Sci-Fi",   0.82),
        ("Drama",    0.71),
        ("Thriller", 0.55),
        ("Western",  0.32),
    ]

    private let settingRows: [(label: String, sub: String, icon: String)] = [
        ("Filters & Preferences", "Genres, mood, decade",       "slider.horizontal.3"),
        ("Streaming services",    "Netflix, MUBI, Prime +2",    "play.tv"),
        ("Subscription",          "Flixr Plus · Annual",        "star"),
        ("Notifications",         "New matches · Trailers",     "bell"),
        ("Help & feedback",       "Get in touch",               "questionmark.circle"),
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "14070a"), .black],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
                        HStack {
                            Text("Profile")
                                .font(.flxDisplay(28))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 38, height: 38)
                            }
                            .glassEffect(in: Circle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 12)

                        // User info row
                        HStack(spacing: 14) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "3a1556"), Color(hex: "1a0a30")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                Circle()
                                    .strokeBorder(Color.flxRed.opacity(0.55), lineWidth: 1.5)
                                    .shadow(color: Color.flxRed.opacity(0.25), radius: 12)
                                Text("SR")
                                    .font(.flxDisplay(28))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 72, height: 72)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sam Reed")
                                    .font(.flxDisplay(22))
                                    .foregroundColor(.white)
                                Text("sam@flixr.tv · Member since 2024")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.dFg3)

                                // Flixr Plus badge
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
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Your taste")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.2)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color.dFg3)
                                Spacer()
                                Text("See more")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.flxRed)
                            }

                            ForEach(taste, id: \.0) { row in
                                TasteBar(label: row.0, percent: row.1)
                            }
                        }
                        .padding(16)
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
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Taste bar row

private struct TasteBar: View {
    var label: String
    var percent: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 64, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "B00710"), Color(hex: "E50914"), Color(hex: "FF3340")],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * percent)
                }
            }
            .frame(height: 6)

            Text("\(Int(percent * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.dFg3)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
