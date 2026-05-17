import FirebaseRemoteConfig
import Observation

@Observable
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    // Empty until a real unit ID is pushed via Remote Config — ads simply won't load
    private(set) var adUnitID:    String = ""
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
            "ad_unit_id":    "" as NSObject,
            "swipes_per_ad": 8 as NSObject,
            "ads_enabled":   true as NSObject,
        ])
    }

    func fetchAndActivate() async {
        _ = try? await rc.fetchAndActivate()
        adUnitID    = rc["ad_unit_id"].stringValue
        swipesPerAd = max(1, rc["swipes_per_ad"].numberValue.intValue)
        adsEnabled  = rc["ads_enabled"].boolValue
    }
}
