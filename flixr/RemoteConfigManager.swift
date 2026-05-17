import FirebaseRemoteConfig
import Observation

@Observable
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    // Test ad unit ID is the safe default — production ID is pushed via Remote Config
    static let defaultAdUnitID = "ca-app-pub-3940256099942544/3986624511"

    // Exposed values — updated after every successful fetch
    private(set) var adUnitID:    String = RemoteConfigManager.defaultAdUnitID
    private(set) var swipesPerAd: Int    = 8
    private(set) var adsEnabled:  Bool   = true

    private let rc = RemoteConfig.remoteConfig()

    private init() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        rc.configSettings = settings
        rc.setDefaults([
            "ad_unit_id":    RemoteConfigManager.defaultAdUnitID as NSObject,
            "swipes_per_ad": 8 as NSObject,
            "ads_enabled":   true as NSObject,
        ])
    }

    func fetchAndActivate() async {
        _ = try? await rc.fetchAndActivate()
        let unitID = rc["ad_unit_id"].stringValue
        adUnitID    = unitID.isEmpty ? RemoteConfigManager.defaultAdUnitID : unitID
        swipesPerAd = max(1, rc["swipes_per_ad"].numberValue.intValue)
        adsEnabled  = rc["ads_enabled"].boolValue
    }
}
