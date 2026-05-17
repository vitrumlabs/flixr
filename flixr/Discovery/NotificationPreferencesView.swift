import SwiftUI

struct NotificationPreferencesView: View {
    @Environment(UserLibrary.self) private var library
    @Environment(NotificationManager.self) private var notifManager
    @Environment(\.openURL) private var openURL

    @State private var prefs: NotificationPrefs = .init()

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

                    Text("Notifications")
                        .font(.flxDisplay(32))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 6)

                    Text("Choose what Flixr can notify you about.")
                        .font(.system(size: 14))
                        .foregroundColor(Color.dFg3)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    if !notifManager.systemGranted {
                        permissionBanner
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }

                    VStack(spacing: 0) {
                        prefRow(
                            title: "New Recommendations",
                            subtitle: "Fresh picks based on your taste",
                            icon: "sparkles",
                            isOn: Binding(
                                get: { prefs.newRecommendations },
                                set: { prefs.newRecommendations = $0; save() }
                            )
                        )

                        Divider().background(Color.dLine).padding(.leading, 64)

                        prefRow(
                            title: "Watchlist Reminders",
                            subtitle: "Nudges for movies you've saved",
                            icon: "bookmark",
                            isOn: Binding(
                                get: { prefs.watchlistReminders },
                                set: { prefs.watchlistReminders = $0; save() }
                            )
                        )

                        Divider().background(Color.dLine).padding(.leading, 64)

                        prefRow(
                            title: "Weekly Digest",
                            subtitle: "Your top picks, every week",
                            icon: "calendar",
                            isOn: Binding(
                                get: { prefs.weeklyDigest },
                                set: { prefs.weeklyDigest = $0; save() }
                            )
                        )
                    }
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.dLine, lineWidth: 1))
                    .padding(.horizontal, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            prefs = library.notifPrefs
            Task {
                await notifManager.checkPermission()
                if !notifManager.systemGranted {
                    await notifManager.requestPermission()
                }
            }
        }
    }

    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 18))
                .foregroundColor(.flxRed)

            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications are off")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Enable in Settings to receive updates.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dFg3)
            }

            Spacer()

            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.flxRed)
        }
        .padding(14)
        .background(Color.flxRed.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.flxRed.opacity(0.25), lineWidth: 1))
    }

    private func prefRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.flxRed.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.flxRed.opacity(0.25), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.flxRed)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.dFg3)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.flxRed)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private func save() {
        Task { await library.saveNotifPrefs(prefs) }
    }
}
