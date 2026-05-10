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
  private var syncTask: Task<(), Never>? = nil
  private var isInForeground = false
  private let queueFile = "locations.json"
  private let maxAttempts = 100
  
  @Published var isTracking: Bool = false
  
  var locations: AsyncThrowingStream<[CLLocation], Error> {
    updates
      ?? AsyncThrowingStream(unfolding: {
        []
      })
  }

  let lockQueue: DispatchQueue
  
  init() {
    lockQueue = DispatchQueue(label: "com.skogberglabs.boat.locations", attributes: [])
  }
  
  func appLaunched() {
    log.info("App launched, is tracking locations: \(prefs.isTracking).")
    isTracking = prefs.isTracking
    if prefs.isTracking {
      start()
    }
  }
  
  func onForeground() {
    isInForeground = true
    syncTask = Task {
      await sendAnyLocations(checkRetry: true)
    }
  }
  
  func onBackground() {
    isInForeground = false
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
    manager?.allowsBackgroundLocationUpdates = true
    manager?.activityType = .fitness
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
        try await handleLocations(boatToken: deviceToken)
      } else {
        let device = try await http.createDevice()
        log.info("Created device \(device.name); listening for location updates...")
        prefs.deviceToken = device.token
        try await handleLocations(boatToken: device.token)
      }
    } catch {
      log.warn("Stopped listening to background location updates \(error).")
      stop()
    }
  }
  
  private func handleLocations(boatToken: String) async throws {
    // At most one location per second, emitted in chunks every 3 seconds
    let chunkedLocations = locations.chunked(by: .repeating(every: .seconds(1)))
      .compactMap { arrays in
        if let latest = arrays.joined().last {
          return Locations.toValidLocation(loc: latest)
        }
        return nil
      }
      .chunked(by: .repeating(every: .seconds(3)))
    for try await locs in chunkedLocations {
      if locs.count > 0 {
        let _ = try append(locs: SourceLocations(updates: locs))
        if isInForeground {
          await sendAnyLocations(checkRetry: false)
        }
      }
    }
  }
  
  private static func toValidLocation(loc: CLLocation) -> LocationUpdate? {
    // horizontalAccuracy: "A negative value indicates that the latitude and longitude are invalid."
    if loc.horizontalAccuracy >= 0 {
      let coord = loc.coordinate
      return LocationUpdate(
        longitude: coord.longitude,
        latitude: coord.latitude,
        accuracyMeters: loc.horizontalAccuracy.meters,
        altitude: loc.verticalAccuracy >= 0 ? loc.altitude.meters : nil,
        verticalAccuracy: loc.verticalAccuracy >= 0 ? loc.verticalAccuracy.meters : nil,
        speed: loc.speedAccuracy >= 0 ? loc.speed.metersPerSecond : nil,
        speedAccuracy: loc.speedAccuracy >= 0 ? loc.speedAccuracy.metersPerSecond : nil,
        bearing: loc.courseAccuracy >= 0 ? loc.course : nil,
        bearingAccuracyDegrees: loc.courseAccuracy >= 0 ? loc.courseAccuracy : nil,
        date: loc.timestamp
      )
    } else {
      return nil
    }
  }
  
  private func sendAnyLocations(checkRetry: Bool) async {
    if let deviceToken = prefs.deviceToken {
      do {
        let locs = try pop()
        let count = locs.updates.count
        if locs.updates.count > 0 {
          do {
            let _ = try await http.sendLocations(locs: locs, boatToken: deviceToken)
            log.info("Sent \(count) locations to the server.")
            prefs.locationSuccess()
          } catch {
            let failureCount = prefs.locationFailure()
            if checkRetry && failureCount >= maxAttempts {
              log.error("Failed to send \(count) locations to the server. Encountered \(failureCount) consecutive failures, discarding data.")
            } else {
              log.warn("Failed to send \(count) locations to the server. Trying again later. \(error)")
              let _ = try prepend(locs: locs)
            }
          }
        } else {
          log.info("No location updates, nothing to send.")
        }
      } catch {
        log.warn("Failed to read locations cache. \(error)")
      }
    }
  }

  private func append(locs: SourceLocations) throws -> SourceLocations {
    return try synchronized {
      let old = try self.popInternal()
      let all = SourceLocations(updates: old.updates + locs.updates)
      try self.saveToFile(locations: all)
      return all
    }
  }
  
  private func pop() throws -> SourceLocations {
    return try synchronized {
      return try self.popInternal()
    }
  }
  
  private func prepend(locs: SourceLocations) throws -> SourceLocations {
    return try synchronized {
      let saved = try self.popInternal()
      let all = SourceLocations(updates: locs.updates + saved.updates)
      try self.saveToFile(locations: all)
      return all
    }
  }
  
  private func popInternal() throws -> SourceLocations {
      let locs = readFromFileOrEmpty()
      try saveToFile(locations: SourceLocations.empty)
      return locs
  }
  
  private func synchronized<T>(_ f: @escaping () throws -> T) throws -> T {
    try self.lockQueue.asyncAndWait {
      try f()
    }
  }
  
  private func saveToFile(locations: SourceLocations) throws {
    try Files.shared.save(locations, to: queueFile)
  }
  
  private func readFromFileOrEmpty() -> SourceLocations {
    do {
      return try Files.shared.read(SourceLocations.self, from: queueFile)
    } catch {
      return SourceLocations(updates: [])
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
