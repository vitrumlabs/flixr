import FirebaseRemoteConfig
import Observation

@Observable
final class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    #if DEBUG
    private static let defaultAdUnitID = "ca-app-pub-3940256099942544/3986624511"
    #else
    private static let defaultAdUnitID = "ca-app-pub-4924727642277920/1083653006"
    #endif

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
            "ad_unit_id":    Self.defaultAdUnitID as NSObject,
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
