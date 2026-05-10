import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @State private var showDiscovery = false

    private var isLoggedIn: Bool { showDiscovery || auth.user != nil }

    var body: some View {
        ZStack {
            if isLoggedIn {
                DiscoveryFlowView()
                    .transition(.opacity)
            } else {
                LoginFlowView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.35)) { showDiscovery = true }
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isLoggedIn)
    }
}

#Preview {
    ContentView()
}
