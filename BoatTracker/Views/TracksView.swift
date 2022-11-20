import Foundation
import SwiftUI

struct TracksView<T>: View where T: TracksProtocol {
    let lang: SummaryLang
    @ObservedObject var vm: T
    @State var rename: TrackRef? = nil
    
    var body: some View {
        List {
            ForEach(vm.tracks) { track in
                TrackView(lang: lang, track: track) {
                    rename = track
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.tracks)
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

struct TracksPreviews: PreviewProvider {
    class PreviewsVM: TracksProtocol {
        var tracks: [TrackRef] { [] }
        func load() async {
        }
        func changeTitle(track: TrackName, title: TrackTitle) async {
        }
    }
    static var previews: some View {
        Group {
            NavigationView {
                TracksView(lang: SummaryLang.preview, vm: PreviewsVM())
            }
        }
    }
}
