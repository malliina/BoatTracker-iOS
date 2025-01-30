import CoreLocation
import Foundation
import SwiftUI

enum DataState {
  case idle
  case loading
}

struct TracksView<T>: View where T: TracksProtocol {
  let lang: SummaryLang
  @ObservedObject var activeTrack: ActiveTrack

  @EnvironmentObject var vm: T
  @State var rename: TrackRef? = nil

  let onSelect: () -> Void

  var body: some View {
    statefulView(state: vm.state)
      .navigationBarTitleDisplayMode(.large)
      .navigationTitle(lang.tracks)
      .navigationViewStyle(.stack)
      .task {
        await vm.load()
      }
      .sheet(item: $rename) { track in
        EditDialog(
          navTitle: lang.rename, title: lang.rename, message: lang.newName,
          initialValue: track.trackTitle?.title ?? "", ctaTitle: lang.rename,
          cancel: lang.cancel
        ) { newValue in
          await vm.changeTitle(
            track: track.trackName, title: TrackTitle(newValue))
        }
      }
  }

  @ViewBuilder
  private func statefulView(state: ViewState) -> some View {
    switch state {
    case .loading:
      LoadingView()
    case .content:
      listView(ts: vm.tracks)
    default:
      Text("")
    }
  }

  private func listView(ts: [TrackRef]) -> some View {
    BoatList(rowSeparator: .automatic) {
      ForEach(vm.tracks) { track in
        Button {
          activeTrack.select(track.trackName)
          onSelect()
        } label: {
          TrackView(lang: lang, track: track) {
            rename = track
          }
        }
      }
      if vm.hasMore {
        HStack {
          Spacer()
          ProgressView().task {
            await vm.loadMore()
          }
          Spacer()
        }
      }
    }
  }
}

struct TracksLang {
  let tracks, distance, duration, topSpeed: String
}

protocol TracksProtocol: ObservableObject {
  var state: ViewState { get }
  var tracks: [TrackRef] { get }
  var hasMore: Bool { get }
  func load() async
  func loadMore() async
  func changeTitle(track: TrackName, title: TrackTitle) async
}

class TracksViewModel: TracksProtocol {
  private let log = LoggerFactory.shared.vc(TracksViewModel.self)

  @Published var state: ViewState = .idle
  @Published var tracks: [TrackRef] = []
  @Published private(set) var hasMore = false

  let limit = 50

  func load() async {
    if tracks.isEmpty {
      await update(viewState: .loading)
    }
    do {
      let batch = try await http.tracks(limit: limit, offset: tracks.count)
      await update(ts: tracks + batch, hasMore: batch.count == limit)
    } catch {
      log.error("Failed to load tracks. \(error.describe)")
      await update(error: error)
    }
  }

  func loadMore() async {
    log.info(
      "Loading more tracks with limit \(limit) and offset \(tracks.count)...")
    await load()
  }

  func changeTitle(track: TrackName, title: TrackTitle) async {
    do {
      let res = try await http.changeTrackTitle(name: track, title: title)
      log.info(
        "Updated title of \(res.track.trackName) to \(res.track.trackTitle?.title ?? "no title")"
      )
      await update(
        ts: try await http.tracks(limit: tracks.count, offset: 0),
        hasMore: self.hasMore)
    } catch {
      log.error("Failed to rename track \(track) to \(title).")
      await update(error: error)
    }
  }

  @MainActor private func update(ts: [TrackRef], hasMore: Bool) {
    tracks = ts
    self.hasMore = hasMore
    state = ts.isEmpty ? .empty : .content
  }

  @MainActor private func update(error: Error) {
    //    self.error = error
    state = .failed
  }

  @MainActor private func update(viewState: ViewState) {
    state = viewState
  }
}

struct TracksPreviews: BoatPreviewProvider, PreviewProvider {
  class PreviewsVM: TracksProtocol {
    let state: ViewState = .content
    var hasMore: Bool = true
    let timing = Timing(
      date: "Today", time: "Time", dateTime: "Date time", millis: 1)
    var tracks: [TrackRef] {
      [
        previewTrack(
          name: "N1", title: "Hej", boatName: "Titanic", source: .boat),
        previewTrack(
          name: "N2", title: "Very long evening ride from the harbor home",
          boatName: "Mos",
          source: .vehicle),
        previewTrack(name: "N3", title: nil, boatName: "Amina", source: .boat),
      ]
    }
    func load() async {}
    func loadMore() async {}
    func selectTrack(track: TrackName) {}
    func changeTitle(track: TrackName, title: TrackTitle) async {}

    func previewTrack(
      name: String, title: String?, boatName: String, source: SourceType
    )
      -> TrackRef
    {
      TrackRef(
        trackName: TrackName(name),
        trackTitle: title != nil ? TrackTitle(title!) : nil,
        boatName: BoatName(boatName), username: Username("Jack"),
        sourceType: source,
        topSpeed: 14.knots, avgSpeed: 11.knots, distanceMeters: 12121.meters,
        duration: 14.seconds,
        avgWaterTemp: 14.celsius, avgOutsideTemp: 18.celsius,
        topPoint: CoordBody(
          coord: CLLocationCoordinate2D(latitude: 24, longitude: 64),
          boatTimeMillis: 1,
          speed: 18.knots, depthMeters: 10.meters, waterTemp: 10.celsius,
          outsideTemp: 11.celsius,
          altitude: 111.meters, time: timing),
        times: Times(start: timing, end: timing, range: "Yesterday - today"))
    }
  }
  static var preview: some View {
    NavigationView {
      TracksView<PreviewsVM>(
        lang: SummaryLang.build(lang), activeTrack: ActiveTrack()
      ) {

      }.environmentObject(PreviewsVM())
    }
  }
}
