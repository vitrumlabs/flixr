import SwiftUI

struct MoodPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "theatermasks")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)
                Text("Mood")
                    .font(.title2.weight(.semibold))
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .preferredColorScheme(.dark)
    }
}
