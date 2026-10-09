platform :ios, '15.0'

target 'Bachon ki duniya' do
  use_frameworks!
  # Debug-only network inspector (shake device, or two-finger double-tap).
  # Pin 1.7.x — Wormholy 2.x needs iOS 16 and was installing without Sources/link flags.
  pod 'Wormholy', '~> 1.7.0', :configurations => ['Debug']
  pod 'IQKeyboardManagerSwift'
  pod 'Alamofire'
  pod 'SDWebImage'

  # Firebase
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseMessaging'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
