import SwiftUI
import FirebaseAuth
import SafariServices

// MARK: - Screen 23: Profile

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(UserLibrary.self) private var library

    @State private var mailUnavailable = false
    @State private var activeLegal: LegalDestination? = nil
    @State private var showNotifPrefs = false
    @State private var showDeleteAccount = false

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

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    private let settingRows: [(label: String, sub: String, icon: String)] = [
        ("Notifications", "Recommendations · Reminders", "bell"),
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
                        .font(.flxDisplay(32))
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
                                AsyncImage(url: photoURL) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable().scaledToFill().clipShape(Circle())
                                    } else {
                                        Text(initials).font(.flxDisplay(28)).foregroundColor(.white)
                                    }
                                }
                            } else {
                                Text(initials).font(.flxDisplay(28)).foregroundColor(.white)
                            }
                        }
                        .frame(width: 72, height: 72)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.flxDisplay(22))
                                .foregroundColor(.white)

                            if let email = user?.email {
                                Text(email)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.dFg3)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            if !memberSince.isEmpty {
                                Text(memberSince)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.dFg3)
                            }

                            if library.isFlixrPlus {
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
                    ProfileRowGroup(rows: settingRows) { label in
                        if label == "Notifications" { showNotifPrefs = true }
                    }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Support & legal
                    ProfileRowGroup(rows: [
                        ("Help & feedback", "Get in touch",          "questionmark.circle"),
                        ("Terms of Use",    "Read our terms",        "doc.text"),
                        ("Privacy Policy",  "How we use your data",  "lock.shield"),
                    ]) { label in
                        switch label {
                        case "Help & feedback": openMail()
                        case "Terms of Use":    activeLegal = .terms
                        case "Privacy Policy":  activeLegal = .privacy
                        default: break
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Delete account
                    ProfileRowGroup(
                        rows: [("Delete Account", "Permanently removes all data", "person.crop.circle.badge.minus")],
                        action: { _ in showDeleteAccount = true },
                        isDestructive: true
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // Sign out — minimal, below everything else
                    Button(action: { auth.signOut() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                            Text("Sign Out")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color.dFg3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Version
                    Text(appVersion)
                        .font(.system(size: 12))
                        .foregroundColor(Color.dFg3.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 110)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNotifPrefs) {
            NotificationPreferencesView()
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
        }
        .sheet(item: $activeLegal) { dest in
            SafariView(url: dest.url)
                .ignoresSafeArea()
        }
        .alert("Mail Not Available", isPresented: $mailUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please reach us directly at info@vitrumlabs.com")
        }
    }

    private func openMail() {
        let subject = "Flixr Help & Feedback"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        guard let url = URL(string: "mailto:info@vitrumlabs.com?subject=\(encoded)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            mailUnavailable = true
        }
    }
}

// MARK: - Delete Account screen

private struct DeleteAccountView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var isDeleting = false
    @State private var deleteError: String? = nil

    private let consequences: [(String, String)] = [
        ("Your profile and login",          "person.crop.circle"),
        ("Your watchlist and saved films",   "bookmark"),
        ("Your taste profile",              "sparkles"),
        ("All preferences and activity",    "chart.bar"),
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
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .padding(.leading, 16)
                    Spacer()
                }
                .padding(.top, 14)
                .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .overlay(Circle().strokeBorder(Color.red.opacity(0.3), lineWidth: 1.5))
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 36))
                                .foregroundColor(.red)
                        }
                        .frame(width: 88, height: 88)
                        .padding(.top, 28)
                        .padding(.bottom, 20)

                        Text("Delete Account")
                            .font(.flxDisplay(28))
                            .foregroundColor(.white)
                            .padding(.bottom, 10)

                        Text("This permanently deletes your account and all data. There is no going back.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.dFg3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                            .padding(.bottom, 32)

                        VStack(spacing: 0) {
                            ForEach(Array(consequences.enumerated()), id: \.element.0) { i, item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.1)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red.opacity(0.65))
                                        .frame(width: 20)
                                    Text(item.0)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.dFg2)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                if i < consequences.count - 1 {
                                    Divider().background(Color.dLine).padding(.leading, 50)
                                }
                            }
                        }
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                        if let error = deleteError {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }

                        Button(action: {
                            isDeleting = true
                            Task {
                                do {
                                    try await auth.deleteAccount()
                                } catch {
                                    deleteError = "Couldn't delete your account. Please sign out and sign back in, then try again."
                                    isDeleting = false
                                }
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isDeleting {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                }
                                Text(isDeleting ? "Deleting…" : "Delete My Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isDeleting ? Color.red.opacity(0.5) : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 110)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Legal destination

enum LegalDestination: String, Identifiable {
    case terms, privacy

    var id: String { rawValue }

    var url: URL {
        switch self {
        case .terms:   return URL(string: "https://vitrumlabs.com/terms")!
        case .privacy: return URL(string: "https://vitrumlabs.com/privacy")!
        }
    }
}

// MARK: - Safari sheet

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = UIColor(Color(hex: "14070a"))
        vc.preferredControlTintColor = UIColor(Color.flxRed)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Reusable row group

private struct ProfileRowGroup: View {
    let rows: [(label: String, sub: String, icon: String)]
    let action: (String) -> Void
    var showChevron: Bool = true
    var isDestructive: Bool = false

    private var accent: Color { isDestructive ? .red : .flxRed }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.label) { i, row in
                Button(action: { action(row.label) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accent.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(accent.opacity(0.25), lineWidth: 1))
                            Image(systemName: row.icon)
                                .font(.system(size: 15))
                                .foregroundColor(accent)
                        }
                        .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isDestructive ? .red : .white)
                            Text(row.sub)
                                .font(.system(size: 12))
                                .foregroundColor(Color.dFg3)
                        }

                        Spacer()

                        if showChevron {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(Color.dFg3)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if i < rows.count - 1 {
                    Divider()
                        .background(Color.dLine)
                        .padding(.leading, 64)
                }
            }
        }
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
    }
}

// MARK: - Genre chips (wrapping flow layout)

private struct GenreChips: View {
    var genres: [String]

    var body: some View {
        ChipFlow(spacing: 8) {
            ForEach(genres, id: \.self) { genre in
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

private struct ChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowX: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > maxWidth, rowX > 0 {
                height += rowHeight + spacing
                rowX = 0
                rowHeight = 0
            }
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
