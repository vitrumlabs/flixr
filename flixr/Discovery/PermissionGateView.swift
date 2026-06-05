import AppTrackingTransparency
import FirebaseAnalytics
import SwiftUI
import UserNotifications

// MARK: - PermissionGateView
//
// Shown once per install after first login.  Presents two sequential
// permission steps — ATT then notifications — before handing control
// back to DiscoveryFlowView.
//
// The gate is skipped on subsequent launches via the UserDefaults key
// `hasSeenPermissionGate`.

private let hasSeenPermissionGateKey = "hasSeenPermissionGate"

struct PermissionGateView: View {
    var onComplete: () -> Void

    @State private var step: Step = .att
    @State private var isRequesting = false

    private enum Step { case att, notifications }

    var body: some View {
        ScreenShell(dim: 0.45) {
            VStack(spacing: 0) {
                Spacer()

                iconBadge
                    .padding(.bottom, 20)

                headlineBlock
                    .padding(.bottom, 12)

                bodyText
                    .padding(.bottom, 44)

                Spacer()

                actionButtons
                    .padding(.bottom, 16)

                skipButton
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.28), value: step)
    }

    // MARK: Icon

    @ViewBuilder
    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.flxRed.opacity(0.10))
                .frame(width: 110, height: 110)
                .shadow(color: Color.flxRed.opacity(0.30), radius: 30)
            Image(systemName: step == .att ? "chart.bar.fill" : "bell.badge.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundColor(.flxRed)
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
        .id(step)
    }

    // MARK: Headline

    @ViewBuilder
    private var headlineBlock: some View {
        Group {
            if step == .att {
                DisplayH1(line1: "Ads that", accentLine: "actually help.")
            } else {
                DisplayH1(line1: "Stay in", accentLine: "the loop.")
            }
        }
        .transition(.opacity)
        .id(step)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Body copy

    @ViewBuilder
    private var bodyText: some View {
        Group {
            if step == .att {
                Text("Allow Flixr to use info from this device for personalization. This helps us show you relevant ads and keeps Flixr free.")
            } else {
                Text("Get notified about new movie recommendations tailored to your taste. You can change this at any time in Settings.")
            }
        }
        .font(.system(size: 16))
        .foregroundColor(.fg2)
        .lineSpacing(3)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
        .id(step)
    }

    // MARK: Buttons

    private var primaryTitle: String {
        step == .att ? "Allow Tracking" : "Allow Notifications"
    }

    @ViewBuilder
    private var actionButtons: some View {
        FlxButton(
            title: primaryTitle,
            variant: .primary,
            icon: "arrow.right",
            isDisabled: isRequesting
        ) {
            Task { await handleAllow() }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        Button("Not now") {
            Task { await advance() }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(.fg3)
        .frame(height: 44)
    }

    // MARK: Logic

    private func handleAllow() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        if step == .att {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            Analytics.logAttConsent(status)
        } else {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            }
        }

        await advance()
    }

    private func advance() async {
        if step == .att {
            await MainActor.run { step = .notifications }
        } else {
            markSeen()
            await MainActor.run { onComplete() }
        }
    }

    private func markSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenPermissionGateKey)
    }
}

// MARK: - Convenience

extension PermissionGateView {
    /// Returns `true` when the gate has already been shown and dismissed.
    static var hasBeenSeen: Bool {
        UserDefaults.standard.bool(forKey: hasSeenPermissionGateKey)
    }
}
