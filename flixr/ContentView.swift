import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        ZStack {
            if auth.user != nil {
                DiscoveryFlowView()
                    .transition(.opacity)
            } else {
                LoginFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.user == nil)
    }
}

#Preview {
    ContentView()
}
