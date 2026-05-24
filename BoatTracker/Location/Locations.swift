import CoreLocation

class Locations {
  static let shared = Locations()
  
  let log = LoggerFactory.shared.system(Locations.self)

  var manager: CLLocationManager?
  let http = Backend.shared.http
  let uploadUrl: URL
  let prefs = BoatPrefs.shared
  private var delegate: LocationsDelegate?
  private var backgroundSession: CLBackgroundActivitySession?
  private var updates: AsyncThrowingStream<[CLLocation], Error>?
  private var cancellables: [Task<(), Never>] = []
  private var syncTask: Task<(), Never>? = nil
  private var isInForeground = false
  private let maxAttempts = 100
  
  @Published var isTracking: Bool = false
  
  var locations: AsyncThrowingStream<[CLLocation], Error> {
    updates
      ?? AsyncThrowingStream(unfolding: {
        []
      })
  }

  let lockQueue: DispatchQueue
  let files: Files
  
  init() {
    lockQueue = DispatchQueue(label: "com.skogberglabs.boat.locations", attributes: [])
    files = Files.documents.folder(name: "locations")
    uploadUrl = URL(string: "/locations", relativeTo: http.baseUrl)!
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
      await sendPersistedLocations()
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
      .chunked(by: .repeating(every: .seconds(5)))
    for try await locs in chunkedLocations {
      if locs.count > 0 {
        try files.save(SourceLocations(updates: locs), to: "\(Date.now.timeIntervalSince1970)-locations.json")
        await sendPersistedLocations()
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
  
  private func sendPersistedLocations() async {
    if let deviceToken = prefs.deviceToken {
      do {
        try await BackgroundTransfers.shared.uploadAll(to: uploadUrl, headers: [Headers.boatToken: deviceToken, Headers.contentType: HttpClient.json])
      } catch {
        log.warn("Failed to upload locations. \(error)")
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
