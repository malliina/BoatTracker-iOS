import CoreLocation

class Locations {
  static let shared = Locations()
  
  let log = LoggerFactory.shared.system(Locations.self)

  var manager: CLLocationManager?
  let http = Backend.shared.http
  let prefs = BoatPrefs.shared
  private var delegate: LocationsDelegate?
  private var backgroundSession: CLBackgroundActivitySession?
  private var updates: AsyncThrowingStream<[CLLocation], Error>?
  private var cancellables: [Task<(), Never>] = []
  
  @Published var isTracking: Bool = false
  
  var locations: AsyncThrowingStream<[CLLocation], Error> {
    updates
      ?? AsyncThrowingStream(unfolding: {
        []
      })
  }

  func appLaunched() {
    log.info("App launched, is tracking locations: \(prefs.isTracking).")
    isTracking = prefs.isTracking
    if prefs.isTracking {
      start()
    }
  }
  
  func start() {
    setup()
    let task = Task {
      await listen()
    }
    cancellables = [task]
  }
  
  private func setup() {
    backgroundSession = CLBackgroundActivitySession()
    manager = CLLocationManager()
    updates = AsyncThrowingStream(bufferingPolicy: .bufferingNewest(1)) { cont in
      self.delegate = LocationsDelegate(cont: cont, locations: self)
      manager?.delegate = self.delegate
      cont.onTermination = { @Sendable _ in
        self.manager?.stopUpdatingLocation()
      }
    }
  }
  
  func listen() async {
    do {
      if let deviceToken = prefs.deviceToken {
        log.info("Listening for location updates...")
        try await sendLocations(boatToken: deviceToken)
      } else {
        let device = try await http.createDevice()
        log.info("Created device \(device.name); listening for location updates...")
        prefs.deviceToken = device.token
        try await sendLocations(boatToken: device.token)
      }
    } catch {
      log.warn("Stopped listening to background location updates \(error).")
      stop()
    }
  }
  
  private func sendLocations(boatToken: String) async throws {
    for try await locs in locations {
      if locs.count > 0 {
        let updates = locs.map { loc in
          let coord = loc.coordinate
          return LocationUpdate(longitude: coord.longitude, latitude: coord.latitude, date: Date.now)
        }
        let _ = try await http.sendLocations(locs: updates, boatToken: boatToken)
      }
      
    }
  }

  func stop() {
    backgroundSession?.invalidate()
    manager?.stopUpdatingLocation()
    update(tracking: false)
    for cancellable in cancellables {
      cancellable.cancel()
    }
    cancellables = []
  }
  
  func update(tracking: Bool) {
    prefs.isTracking = tracking
    isTracking = tracking
    let word = isTracking ? "Started" : "Stopped"
    log.info("\(word) location tracking.")
  }
}

class LocationsDelegate: NSObject, CLLocationManagerDelegate {
  let log = LoggerFactory.shared.system(LocationsDelegate.self)
  
  private let cont: AsyncThrowingStream<[CLLocation], Error>.Continuation
  private let locations: Locations
  
  let prefs = BoatPrefs.shared
  
  init(cont: AsyncThrowingStream<[CLLocation], Error>.Continuation, locations: Locations) {
    self.cont = cont
    self.locations = locations
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // "the most recent location update is at the end of the array"
    cont.yield(locations)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
    log.error("Locations error \(error)")
    cont.yield(with: .failure(error))
    locations.update(tracking: false)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      log.info("Location services available.")
      manager.startUpdatingLocation()
      locations.update(tracking: true)
      break
    case .restricted, .denied:
      log.info("Location services unavailable.")
      manager.stopUpdatingLocation()
      locations.update(tracking: false)
      break
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
      break
    default:
      break
    }
  }
}
