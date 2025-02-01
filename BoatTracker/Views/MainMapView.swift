import Foundation
import MapboxMaps
import SwiftUI

struct WelcomeInfo: Identifiable {
  let boatToken: String
  let lang: SettingsLang

  var id: String { boatToken }
}

struct TapInfo: Identifiable {
  let id: String
  let result: TapResult
  let point: CGPoint
}

struct TapPosition {
  let x: CGFloat
  let y: CGFloat
}

struct CoordDistance {
  let from: CLLocationCoordinate2D
  let to: CoordBody
  var distance: LocationDistance { from.distance(to: to.coord) }
}

struct RouteState {
  let start: CLLocationCoordinate2D?
  let end: CLLocationCoordinate2D?
}

struct MainMapView<T>: View where T: MapViewModelLike {
  let log = LoggerFactory.shared.view(MainMapView.self)

  @EnvironmentObject var viewModel: T

  @State var welcomeInfo: WelcomeInfo? = nil
  @State var authInfo: Lang? = nil
  @State var profileInfo: ProfileInfo? = nil
  @State var tapResult: Tapped? = nil
  @State var showPopover: Bool = false
  @State var tapInfo: TapInfo? = nil
  @State var tapPosition: TapPosition = TapPosition(x: 0, y: 0)
  @State var viewport: Viewport = .overview(
    geometry: Polygon(center: MapViewModel.defaultCenter, radius: 10000, vertices: 30))
  @State var cameraFitted = false
  @State var hasBeenFollowing = false
  @State var routeState: RouteState = RouteState(start: nil, end: nil)

  var settings: UserSettings { viewModel.settings }

  let boatIconsId = "boat-icons"
  let vesselIconsLayerId = "vessel-icons"
  let trackLayerId = "track"

  @ViewBuilder
  func makePopup(tap: TapResult, lang: Lang, specials: SpecialWords) -> some View {
    switch tap {
    case .vessel(let v):
      VesselView(vessel: v, lang: lang)
    case .mark(let info, _, _):
      MarkView(info: info, lang: lang, finnishWords: specials)
    case .miniMark(let info, _):
      MinimalMarkView(info: info, lang: lang, finnishWords: specials)
    case .trailPoint(let info):
      TrailPointView(info: info, lang: lang)
    case .boat(let info):
      BoatView(info: info, lang: lang)
    case .area(let info, let limit):
      AreaView(info: info, limit: limit, lang: lang)
    case .limit(let info, _):
      LimitView(limit: info, lang: lang)
    case .trophy(let info, _):
      TrophyView(info: info, lang: lang)
    default:
      EmptyView()
    }
  }

  private func makeVesselPoint(vessel: Vessel, icon: String) -> PointAnnotation {
    let meta = VesselMeta(
      mmsi: vessel.mmsi, name: vessel.name, heading: vessel.heading ?? vessel.cog)
    var pa = PointAnnotation(coordinate: vessel.coord)
      .iconImage(icon)
      .iconSize(0.7)
      .iconHaloColor(.white)
      .iconRotate(vessel.heading ?? 0.0)
    pa.customData = (try? Json.shared.write(from: meta)) ?? [:]
    return pa
  }

  private func makeBoatPoint(track: SingleTrackPoint) -> PointAnnotation {
    let from = track.from
    let isBoat = from.sourceType.isBoat
    var pa = PointAnnotation(coordinate: track.point.coord)
      .iconImage(isBoat ? Layers.boatIcon : Layers.carIcon)
      .iconSize(isBoat ? 0.7 : 0.5)
      .iconRotate(track.bearing ?? 0)
    pa.customData = (try? Json.shared.write(from: track)) ?? [:]
    return pa
  }

  private func makeTrophy(point: TrophyPoint) -> PointAnnotation {
    var pa = PointAnnotation(coordinate: point.top.coord)
      .iconImage(Layers.trophyIcon)
    pa.customData = (try? Json.shared.write(from: point)) ?? [:]
    return pa
  }

  private func makePolyline(track: CoordsData) -> PolylineAnnotation {
    var polyline = PolylineAnnotation(lineCoordinates: track.coords.map { $0.coord })
    polyline.customData = (try? Json.shared.write(from: track.from)) ?? [:]
    return polyline
  }

  private func parseCustom<C: Decodable>(_ t: C.Type, from: Feature) -> C? {
    if let props = from.properties, let custom = props["custom_data"], let value = custom {
      return try? Json.shared.parse(t, from: value)
    } else {
      return nil
    }
  }

  private func parseProps<C: Decodable>(_ t: C.Type, from: Feature) -> C? {
    let props = from.properties ?? [:]
    return try? Json.shared.parse(t, from: props)
  }

  private func updatePopup(tap: TapResult, point: CGPoint, size: CGSize) {
    tapPosition = TapPosition(x: point.x / size.width, y: point.y / size.height)
    tapInfo = TapInfo(id: "tap-\(Date.now.timeIntervalSince1970)", result: tap, point: point)
  }

  private func queryLimits(at: CGPoint, map: MapboxMap) async -> LimitArea? {
    if let conf = settings.conf,
      let raw = await map.queryVisibleFeatureProps(
        at, layers: conf.layers.limits, t: RawLimitArea.self),
      let limits = try? raw.validate()
    {
      return limits
    }
    return nil
  }

  var body: some View {
    VStack {
      if let styleUri = viewModel.styleUri, let conf = settings.conf {
        ZStack(alignment: .topLeading) {
          GeometryReader { reader in
            MapReader { proxy in
              Map(viewport: $viewport) {
                PointAnnotationGroup(viewModel.allVessels, id: \.mmsi.mmsi) { vessel in
                  makeVesselPoint(vessel: vessel, icon: conf.layers.ais.vesselIcon)
                }
                .layerId(vesselIconsLayerId)
                .iconRotationAlignment(.map)
                // Visible
                PolylineAnnotationGroup(viewModel.tracks) { track in
                  let isLatest =
                    viewModel.latestTrackPoints.find { stp in
                      stp.from.trackName == track.from.trackName
                    } != nil
                  return makePolyline(track: track)
                    .lineOpacity(isLatest ? 1.0 : 0.4)
                }
                // Tappable, invisible
                PolylineAnnotationGroup(viewModel.tracks) { track in
                  makePolyline(track: track)
                    .lineWidth(10)
                    .lineOpacity(0.01)
                }
                .layerId(trackLayerId)
                PointAnnotationGroup(viewModel.latestTrackPoints, id: \.from.trackName) { track in
                  makeBoatPoint(track: track)
                }
                .layerId(boatIconsId)
                .iconRotationAlignment(.map)
                if let latest = viewModel.tracks.last {
                  let point = TrophyPoint(from: latest.from)
                  makeTrophy(point: point)
                    .onTapGesture { ctx in
                      updatePopup(
                        tap: .trophy(
                          info: TrophyInfo.fromPoint(trophyPoint: point), at: point.top.coord),
                        point: ctx.point, size: reader.realSize)
                      return true
                    }
                }
                if let route = viewModel.routeResult {
                  let fairwayPath = route.route.links.map { $0.to }
                  PolylineAnnotation(lineCoordinates: fairwayPath)
                  PolylineAnnotationGroup {
                    PolylineAnnotation(lineCoordinates: [
                      route.from, fairwayPath.first ?? route.from,
                    ])
                    PolylineAnnotation(lineCoordinates: [fairwayPath.last ?? route.from, route.to])
                  }.lineDasharray([2, 4])
                }
              }
              .mapStyle(.init(uri: styleUri))
              .onLayersTapGesture(conf.layers.marks) { qf, ctx in
                if let result = Tapped.markResult(qf.feature, point: ctx.point) {
                  updatePopup(tap: result, point: ctx.point, size: reader.realSize)
                  return true
                } else {
                  return false
                }
              }
              .onLayersTapGesture(conf.layers.fairwayAreas) { qf, ctx in
                if let result = parseProps(FairwayArea.self, from: qf.feature) {
                  Task {
                    if let map = proxy.map {
                      let limits = await queryLimits(at: ctx.point, map: map)
                      let area: TapResult = .area(info: result, limit: limits)
                      updatePopup(tap: area, point: ctx.point, size: reader.realSize)
                    }
                  }
                  return true
                } else {
                  return false
                }
              }
              .onLayersTapGesture(conf.layers.limits) { qf, ctx in
                if let raw = parseProps(RawLimitArea.self, from: qf.feature),
                  let limits = try? raw.validate()
                {
                  updatePopup(
                    tap: .limit(area: limits, at: ctx.coordinate), point: ctx.point,
                    size: reader.realSize)
                  return true
                } else {
                  return false
                }
              }
              .onLayerTapGesture(vesselIconsLayerId) { (qf, ctx) in
                if let meta = parseCustom(VesselMeta.self, from: qf.feature),
<<<<<<< HEAD
                   let vessel = viewModel.vesselInfo(meta.mmsi) {
=======
                  let vessel = AISState.shared.info(meta.mmsi)
                {
>>>>>>> dcc278cfef65e6695698ce53737e232a163e3dcb
                  updatePopup(tap: .vessel(info: vessel), point: ctx.point, size: reader.realSize)
                  return true
                } else {
                  return false
                }
              }
              .onLayerTapGesture(trackLayerId) { qf, ctx in
                if let from = parseCustom(TrackRef.self, from: qf.feature) {
                  let trail = viewModel.tracks.find { t in
                    t.from.trackName == from.trackName
                  }
                  let tapCoord = ctx.coordinate
                  let closest: CoordBody? = trail?.coords.min { c1, c2 in
                    tapCoord.distance(to: c1.coord) < tapCoord.distance(to: c2.coord)
                  }
                  if let closest = closest {
                    let result: TapResult = .trailPoint(
                      info: SingleTrackPoint(from: from, point: closest, bearing: nil))
                    updatePopup(tap: result, point: ctx.point, size: reader.realSize)
                    return true
                  } else {
                    return false
                  }
                } else {
                  return false
                }
              }
              .onLayerTapGesture(boatIconsId) { qf, ctx in
                if let track = parseCustom(SingleTrackPoint.self, from: qf.feature) {
                  let bp = BoatPoint(from: track.from, coord: track.point)
                  updatePopup(tap: .boat(info: bp), point: ctx.point, size: reader.realSize)
                  return true
                } else {
                  return false
                }
              }
              .gestureHandlers(
                .init(onBegin: { gestureType in
                  if gestureType == .pan {
                    viewModel.mapMode = .stay
                  }
                })
              )
              .onMapLongPressGesture { ctx in
                let coord = ctx.coordinate
                if let _ = routeState.start, let end = routeState.end {
                  routeState = RouteState(start: end, end: coord)
                  viewModel.shortest(from: end, to: coord)
                } else if let start = routeState.start {
                  routeState = RouteState(start: start, end: coord)
                  viewModel.shortest(from: start, to: coord)
                } else {
                  routeState = RouteState(start: coord, end: nil)
                }
              }
              .onReceive(
                viewModel.coordsPublisher.debounce(for: .seconds(1), scheduler: RunLoop.main)
                  .first()
              ) { coords in
                if !cameraFitted {
                  cameraFitted = true
                  let coords = viewModel.tracks.flatMap { cd in
                    cd.coords
                  }
                  if coords.count > 1 {
                    withViewportAnimation {
                      viewport = .overview(
                        geometry: LineString(coords.map { $0.coord }),
                        geometryPadding: .init(top: 30, leading: 20, bottom: 30, trailing: 20))
                    }
                  }
                }
              }
              .onReceive(viewModel.coordsPublisher) { coords in
                if let coords = coords, let latest = coords.coords.last,
                  viewModel.mapMode == .follow
                {
                  let defaultPitch: CGFloat = 60
                  let pitch =
                    hasBeenFollowing
                    ? viewport.camera?.pitch ?? viewport.overview?.pitch ?? defaultPitch
                    : defaultPitch
                  hasBeenFollowing = true
                  if let bearing = MapViewModel.adjustedBearing(data: coords) {
                    withViewportAnimation {
                      viewport = .camera(center: latest.coord, bearing: bearing, pitch: pitch)
                    }
                  } else {
                    viewport = .camera(center: latest.coord)
                  }
                }
              }
              .popover(
                item: $tapInfo, attachmentAnchor: .point(.init(x: tapPosition.x, y: tapPosition.y))
              ) { info in
                if let lang = settings.lang, let specials = settings.languages?.finnish.specialWords
                {
                  if #available(iOS 16.4, *) {
                    makePopup(tap: info.result, lang: lang, specials: specials)
                      .presentationCompactAdaptation(.popover)
                  } else {
                    makePopup(tap: info.result, lang: lang, specials: specials)
                  }
                } else {
                  EmptyView()
                }
              }
              .ignoresSafeArea()
            }
          }
          if !viewModel.isProfileButtonHidden {
            MapButtonView(imageResource: "SettingsSlider") {
              guard let lang = settings.lang else { return }
              if let user = viewModel.latestToken {
                profileInfo = ProfileInfo(user: user, current: viewModel.latestTrack, lang: lang)
              } else {
                authInfo = lang
              }
            }
            .offset(x: 16, y: 16)
            .opacity(0.6)
          }
          if !viewModel.isFollowButtonHidden {
            MapButtonView(imageResource: "LocationArrow") {
              if viewModel.mapMode != .follow {
                viewModel.mapMode = .follow
                if let latestTrack = viewModel.latestTrack,
                  let latest = viewModel.tracks.find({ cd in
                    cd.from.trackName == latestTrack
                  }), let last = latest.coords.last
                {
                  withViewportAnimation {
                    viewport = .camera(center: last.coord)
                  }
                }
              } else {
                viewModel.mapMode = .stay
              }
            }
            .offset(x: 16, y: 60)
            .opacity(viewModel.mapMode == .follow ? 0.3 : 0.6)
          }
        }
      }
    }
    .sheet(item: $welcomeInfo) { info in
      NavigationView {
        WelcomeView(lang: info.lang, token: info.boatToken)
          .navigationBarTitleDisplayMode(.large)
          .navigationTitle(info.lang.welcome)
          .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button {
                welcomeInfo = nil
              } label: {
                Text(info.lang.done)
              }
            }
          }
      }
    }
    .sheet(item: $profileInfo) { info in
      NavigationView {
        ProfileView<ProfileVM>(info: info)
          .environmentObject(viewModel.activeTrack)
          .navigationBarTitleDisplayMode(.large)
          .navigationTitle(info.lang.appName)
          .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
              Button {
                profileInfo = nil
              } label: {
                Text(info.lang.map)
              }
            }
          }
      }
    }
    .sheet(item: $authInfo) { info in
      NavigationView {
        AuthView(welcomeInfo: $welcomeInfo, lang: info)
          .navigationBarTitleDisplayMode(.large)
          .navigationTitle(info.settings.signIn)
          .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
              Button {
                authInfo = nil
              } label: {
                Text(info.settings.cancel)
              }
            }
          }
      }
    }
  }
}

struct MainMapViewPreviews: BoatPreviewProvider, PreviewProvider {
  static var preview: some View {
    MainMapView<PreviewMapViewModel>()
      .environmentObject(PreviewMapViewModel())
  }
}
