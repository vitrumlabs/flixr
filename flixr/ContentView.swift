import SwiftUI

struct ContentView: View {
    @State private var showDiscovery = false

    var body: some View {
        ZStack {
            if showDiscovery {
                DiscoveryFlowView()
                    .transition(.opacity)
            } else {
                LoginFlowView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.35)) { showDiscovery = true }
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showDiscovery)
    }
}

#Preview {
    ContentView()
}
