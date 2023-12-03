import Foundation
import CoreLocation

/// See https://developer.apple.com/documentation/corelocation/configuring_your_app_to_use_location_services
///
/// Before you start any location services, you must request authorization from the owner of the device.
class BoatLocationManager: NSObject, CLLocationManagerDelegate {
  let log = LoggerFactory.shared.system(BoatLocationManager.self)
  
  static let shared = BoatLocationManager()
  
  private var locationManager: CLLocationManager? = nil
  
//  @Published var authorizationStatus: CLAuthorizationStatus? = nil
  @Published var locations: [CLLocation] = []
  @Published var isTracking: Bool = false
  
  var latestLocation: CLLocation? { locations.last }
  
  func startOrRequestAuthorization() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
  }
  
//  func startOrRequestAuthorization() {
//    locationManager.delegate = self
//    let status = locationManager.authorizationStatus
//    switch status {
//    case .notDetermined: 
//      locationManager.requestWhenInUseAuthorization()
//    case .authorizedAlways, .authorizedWhenInUse:
//      startTracking()
//    default: break
//    }
//  }
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let described = describe(status: manager.authorizationStatus)
    log.info("Location authorization status is \(described)")
//    authorizationStatus = manager.authorizationStatus
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      startTracking()
      break
    case .restricted, .denied:
      stopTracking()
      break
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
      break
    default:
      break
    }
  }
  
  /// locations is an array of CLLocation objects in chronological order.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    log.info("Got \(locations.count) location updates.")
    if let latest = locations.last {
      log.info("Latest location is \(latest.coordinate.latitude), \(latest.coordinate.longitude)")
    }
    self.locations = locations
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    log.error("Location manager failed. \(error)")
  }
  
  private func startTracking() {
    locationManager?.startUpdatingLocation()
    isTracking = true
    log.info("Started location tracking.")
  }
  
  func stopTracking() {
    locationManager?.stopUpdatingLocation()
    isTracking = false
    log.info("Stopped location tracking.")
  }
  
  private func describe(status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
      return "not determined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorizedAlways:
      return "always authorized"
    case .authorizedWhenInUse:
      return "authorized when in use"
    case .authorized:
      return "authorized"
    default:
      return "unknown"
    }
  }
}
