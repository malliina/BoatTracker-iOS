# Uncomment the next line to define a global platform for your project
platform :ios, '11.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"

target 'BoatTracker' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # https://stackoverflow.com/a/13209057
  inhibit_all_warnings!

  pod 'AppCenter', '1.7.1'
  pod 'Charts', '3.2.1'
  pod 'GoogleSignIn', '4.3.0'
  pod 'Mapbox-iOS-SDK', '4.9.0'
  pod 'RxCocoa', '4.4.1'
  pod 'RxSwift', '4.4.1'
  pod 'SnapKit', '4.0.1'
  pod 'SocketRocket', '0.5.1'
  
  target 'BoatTrackerTests' do
      inherit! :search_paths
      # Pods for testing
  end
  
  target 'BoatTrackerUITests' do
      inherit! :search_paths
      # Pods for testing
      pod 'Mapbox-iOS-SDK', '4.9.0'
  end
end
