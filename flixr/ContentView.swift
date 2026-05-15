import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(UserLibrary.self) private var library

    var body: some View {
        ZStack {
            if !auth.isReady {
                LoadingView(title: "Flixr", sub: "Finding your next watch…")
                    .transition(.opacity)
            } else if auth.isSigningOut {
                LoadingView(title: "Signing out", sub: "See you next time.")
                    .transition(.opacity)
            } else if auth.user != nil {
                DiscoveryFlowView()
                    .transition(.opacity)
            } else {
                LoginFlowView(onComplete: { auth.acceptCurrentUser() })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isReady)
        .animation(.easeInOut(duration: 0.35), value: auth.isSigningOut)
        .animation(.easeInOut(duration: 0.35), value: auth.user == nil)
        .task(id: auth.uid) {
            if auth.uid != nil { await library.load() }
        }
    }
}

#Preview {
    ContentView()
}
