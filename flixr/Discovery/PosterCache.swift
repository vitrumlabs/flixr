import UIKit

/// Loads and caches poster images outside the SwiftUI view tree so that
/// Firestore-triggered re-renders never reset loading state.
@Observable
final class PosterCache {
    static let shared = PosterCache()

    private var images: [URL: UIImage] = [:]
    private var inFlight: Set<URL> = []

    func image(for url: URL) -> UIImage? { images[url] }

    func load(url: URL) {
        guard images[url] == nil, !inFlight.contains(url) else { return }
        inFlight.insert(url)
        Task.detached(priority: .utility) {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = UIImage(data: data) else {
                await MainActor.run { self.inFlight.remove(url) }
                return
            }
            await MainActor.run {
                self.images[url] = img
                self.inFlight.remove(url)
            }
        }
    }

    func prefetch(urls: [URL]) {
        for url in urls { load(url: url) }
    }
}
