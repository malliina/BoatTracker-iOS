# Uncomment the next line to define a global platform for your project
platform :ios, '11.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"

def app_pods
    pod 'AppCenter', '1.14.0'
    pod 'Charts', '3.3.0'
    pod 'GoogleSignIn', '4.4.0'
    pod 'Mapbox-iOS-SDK', '4.10.0'
    pod 'RxCocoa', '4.5.0'
    pod 'RxSwift', '4.5.0'
    pod 'SnapKit', '4.2.0'
    pod 'SocketRocket', '0.5.1'
end

target 'BoatTracker' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  # https://stackoverflow.com/a/13209057
  inhibit_all_warnings!

  app_pods
  
  target 'BoatTrackerTests' do
      inherit! :search_paths
  end
  
  target 'BoatTrackerUITests' do
      inherit! :search_paths
      pod 'Charts', '3.3.0'
      pod 'Mapbox-iOS-SDK', '4.10.0'
  end
end
