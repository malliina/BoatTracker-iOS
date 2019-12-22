# Uncomment the next line to define a global platform for your project
platform :ios, '11.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"

def app_pods
    pod 'AppCenter', '2.5.3'
    pod 'Charts', '3.4.0'
    pod 'GoogleSignIn', '5.0.2'
    pod 'Mapbox-iOS-SDK', '5.6.0'
    pod 'RxCocoa', '5.0.1'
    pod 'RxSwift', '5.0.1'
    pod 'SnapKit', '5.0.1'
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
        #pod 'AppCenter', '2.5.3'
  end

  target 'BoatTrackerUITests' do
    inherit! :search_paths
      #pod 'GoogleSignIn', '5.0.2'
      #app_pods
  end
end
