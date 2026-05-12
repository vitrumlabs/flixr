import GoogleMobileAds
import Observation

// Loads one NativeAd at a time and publishes it via @Observable.
// Call loadNext() to start/restart loading. The ad property is nil while
// loading or if the request fails — callers should gracefully skip the slot.
@Observable
final class NativeAdLoader: NSObject {
    private(set) var ad: NativeAd?
    private var loader: AdLoader?

    private let adUnitID = "ca-app-pub-3940256099942544/3986624511"

    func loadNext() {
        ad = nil
        loader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        loader?.delegate = self
        loader?.load(Request())
    }
}

extension NativeAdLoader: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        // ad stays nil — the swipe screen will skip the ad slot
    }
}

extension NativeAdLoader: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        ad = nativeAd
    }
}
