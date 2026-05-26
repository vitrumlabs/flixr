platform :ios, '17.0'

target 'flixr' do
  use_frameworks!

  target 'flixrTests' do
    inherit! :search_paths
  end

  pod 'FirebaseAuth'
  pod 'FirebaseAnalytics'
  pod 'FirebaseFirestore'
  pod 'FirebaseFunctions'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseAppCheck'
  pod 'FirebasePerformance'
  pod 'FirebaseRemoteConfig'
  pod 'FirebaseMessaging'
  pod 'GoogleSignIn'
  pod 'Google-Mobile-Ads-SDK'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 17.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      end
    end
  end
end
