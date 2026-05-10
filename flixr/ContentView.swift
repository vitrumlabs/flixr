import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        ZStack {
            if auth.isSigningOut {
                LoadingView(title: "Signing out", sub: "See you next time.")
                    .transition(.opacity)
            } else if auth.user != nil {
                DiscoveryFlowView()
                    .transition(.opacity)
            } else {
                LoginFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isSigningOut)
        .animation(.easeInOut(duration: 0.35), value: auth.user == nil)
    }
}

#Preview {
    ContentView()
}
