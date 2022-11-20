import Foundation
import SwiftUI

struct TracksView<T>: View where T: TracksProtocol {
    let lang: SummaryLang
    @ObservedObject var vm: T
    
    var body: some View {
        List {
            ForEach(vm.tracks) { track in
                TrackView(lang: lang, track: track)
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.tracks)
        .task {
            await vm.load()
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
            log.info("Failed to load tracks. \(error.describe)")
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
}

struct TracksPreviews: PreviewProvider {
    class PreviewsVM: TracksProtocol {
        var tracks: [TrackRef] { [] }
        func load() async {
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
