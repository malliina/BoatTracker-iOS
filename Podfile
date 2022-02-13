# Uncomment the next line to define a global platform for your project
platform :ios, '11.3'
ENV['COCOAPODS_DISABLE_STATS'] = "true"

def app_pods
  pod 'AppCenter', '4.1.0'
  pod 'Charts', '3.6.0'
  pod 'GoogleSignIn', '6.1.0'
  # pod 'Mapbox-iOS-SDK', '6.3.0'
  pod 'MapboxMaps', '10.1.0'
  pod 'MSAL', '1.1.17'
  pod 'RxCocoa', '6.0.0'
  pod 'RxSwift', '6.0.0'
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
  end

  #target 'BoatTrackerUITests' do
  #  inherit! :search_paths
  #end

end
