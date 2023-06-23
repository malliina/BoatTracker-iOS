import Foundation
import CoreLocation
import SwiftUI

struct TracksView<T>: View where T: TracksProtocol {
    let lang: SummaryLang
    @ObservedObject var activeTrack: ActiveTrack
    
    @EnvironmentObject var vm: T
    @State var rename: TrackRef? = nil
    
    let onSelect: () -> Void
    
    var body: some View {
        BoatList(rowSeparator: .automatic) {
            ForEach(vm.tracks) { track in
                Button {
                    activeTrack.selectedTrack = track.trackName
                    onSelect()
                } label: {
                    TrackView(lang: lang, track: track) {
                        rename = track
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.tracks)
        .navigationViewStyle(.stack)
        .task {
            await vm.load()
        }
        .sheet(item: $rename) { track in
            EditDialog(navTitle: lang.rename, title: lang.rename, message: lang.newName, initialValue: track.trackTitle?.title ?? "", ctaTitle: lang.rename, cancel: lang.cancel) { newValue in
                await vm.changeTitle(track: track.trackName, title: TrackTitle(newValue))
            }
        }
    }
}

struct TracksLang {
    let tracks, distance, duration, topSpeed: String
}

class TracksViewModel: TracksProtocol {
    private let log = LoggerFactory.shared.vc(TracksViewModel.self)
    
    @Published var tracks: [TrackRef] = []
    @Published var error: Error?
    
    func load() async {
        do {
            await update(ts: try await http.tracks())
        } catch {
            log.error("Failed to load tracks. \(error.describe)")
            await update(error: error)
        }
    }
    
    func changeTitle(track: TrackName, title: TrackTitle) async {
        do {
            let res = try await http.changeTrackTitle(name: track, title: title)
            log.info("Updated title of \(res.track.trackName) to \(res.track.trackTitle?.title ?? "no title")")
            await update(ts: try await http.tracks())
        } catch {
            log.error("Failed to rename track \(track) to \(title).")
            await update(error: error)
        }
    }
    
    @MainActor private func update(ts: [TrackRef]) {
        self.tracks = ts
    }
    
    @MainActor private func update(error: Error) {
        self.error = error
    }
}

protocol TracksProtocol: ObservableObject {
    var tracks: [TrackRef] { get }
    func load() async
    func changeTitle(track: TrackName, title: TrackTitle) async
}

struct TracksPreviews: BoatPreviewProvider, PreviewProvider {
    class PreviewsVM: TracksProtocol {
        let timing = Timing(date: "Today", time: "Time", dateTime: "Date time", millis: 1)
        var tracks: [TrackRef] { [ previewTrack(name: "N1", title: "Hej", boatName: "Titanic", source: .boat), previewTrack(name: "N2", title: "Very long evening ride from the harbor home", boatName: "Mos", source: .vehicle), previewTrack(name: "N3", title: nil, boatName: "Amina", source: .boat) ] }
        func load() async { }
        func selectTrack(track: TrackName) { }
        func changeTitle(track: TrackName, title: TrackTitle) async { }
        
        func previewTrack(name: String, title: String?, boatName: String, source: SourceType) -> TrackRef {
            TrackRef(trackName: TrackName(name), trackTitle: title != nil ? TrackTitle(title!) : nil, boatName: BoatName(boatName), username: Username("Jack"), sourceType: source, topSpeed: 14.knots, avgSpeed: 11.knots, distanceMeters: 12121.meters, duration: 14.seconds, avgWaterTemp: 14.celsius, avgOutsideTemp: 18.celsius, topPoint: CoordBody(coord: CLLocationCoordinate2D(latitude: 24, longitude: 64), boatTimeMillis: 1, speed: 18.knots, depthMeters: 10.meters, waterTemp: 10.celsius, outsideTemp: 11.celsius, altitude: 111.meters, time: timing), times: Times(start: timing, end: timing, range: "Yesterday - today"))
        }
    }
    static var preview: some View {
        NavigationView {
            TracksView<PreviewsVM>(lang: SummaryLang.build(lang), activeTrack: ActiveTrack()) {
                
            }.environmentObject(PreviewsVM())
        }
    }
}
