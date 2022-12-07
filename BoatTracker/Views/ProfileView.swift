import Foundation
import SwiftUI

struct ProfileInfo: Identifiable {
    let user: UserToken
    let current: TrackName?
    let lang: Lang
    var id: String { user.email }
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    let info: ProfileInfo
    @StateObject var vm: ProfileVM = ProfileVM()
    
    var lang: Lang { info.lang }
    var summaryLang: SummaryLang { SummaryLang.build(lang) }
    var modules: Modules { vm.modules }
    
    var body: some View {
        BoatList {
            BoatSection {
                if let summary = vm.summary, vm.state == .content {
                    TrackSummaryView(track: summary, lang: summaryLang)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if vm.state == .empty {
                    Text(info.lang.messages.noSavedTracks)
                        .foregroundColor(color.secondaryText)
                } else if vm.state == .loading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }.frame(height: 228)
                } else {
                    EmptyView()
                }
            }
            BoatSection {
                if let summary = vm.summary {
                    NavigationLink {
                        ChartsView(lang: ChartLang.build(lang), title: summary.trackTitle?.description ?? summary.startDate, trackName: summary.trackName)
                    } label: {
                        Text(lang.track.graph)
                    }
                }
                NavigationLink {
                    TracksView(lang: summaryLang, vm: modules.tracks) {
                        dismiss()
                    }
                } label: {
                    Text(lang.track.trackHistory)
                }
                NavigationLink {
                    StatsView(lang: lang, vm: modules.stats)
                } label: {
                    Text(lang.labels.statistics)
                }
                NavigationLink {
                    BoatTokensView(lang: TokensLang.build(lang: lang), vm: modules.boats)
                } label: {
                    Text(lang.track.boats)
                }
            }
            BoatSection {
                NavigationLink {
                    SelectLanguageView(lang: lang.profile.languages, vm: modules.languages)
                } label: {
                    Text(lang.profile.language)
                }
            }
            BoatSection {
                NavigationLink {
                    AttributionsView(info: lang.attributions)
                } label: {
                    Text(lang.attributions.title)
                }
            }
            BoatSection {
                if let versionText = vm.versionText(lang: lang) {
                    Text(versionText)
                        .foregroundColor(color.lightGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text("\(lang.profile.signedInAs) \(info.user.email)")
                    .foregroundColor(color.lightGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .task {
            await vm.loadTracks(latest: info.current)
        }
    }
    
    func BoatSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Section(footer: Footer()) {
            content()
        }
        .listRowSeparator(.hidden)
    }
    
    func Footer() -> some View {
        Spacer()
    }
}

class Modules {
    let languages = LanguageVM()
    let tracks = TracksViewModel()
    let boats = BoatTokensVM()
    let stats = StatsViewModel()
}

class ProfileVM: ObservableObject, TracksDelegate {
    let log = LoggerFactory.shared.vc(ProfileVM.self)
    
    @Published var state: ViewState = .idle
    @Published var tracks: [TrackRef] = []
    @Published var current: TrackName? = nil
    
    let modules = Modules()
    
    var summary: TrackRef? {
        tracks.first { ref in
            ref.trackName == current
        }
    }
    
    func onTrack(_ track: TrackName) {
        ActiveTrack.shared.selectedTrack = track
    }
    
    private var socket: BoatSocket { Backend.shared.socket }
    
    func versionText(lang: Lang) -> String? {
        if let bundleMeta = Bundle.main.infoDictionary,
           let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
           let buildId = bundleMeta["CFBundleVersion"] as? String {
            return "\(lang.appMeta.version) \(appVersion) \(lang.appMeta.build) \(buildId)"
        } else {
            return nil
        }
    }

    func loadTracks(latest: TrackName?) async {
        await update(viewState: .loading)
        do {
            let ts = try await http.tracks()
            log.info("Got \(ts.count) tracks.")
            await update(ts: ts, trackName: latest)
        } catch {
            log.error("Unable to load tracks. \(error.describe)")
            await update(viewState: .failed)
        }
    }
    
    @MainActor private func update(viewState: ViewState) {
        state = viewState
    }
    
    @MainActor private func update(ts: [TrackRef], trackName: TrackName?) {
        tracks = ts
        current = trackName
        state = ts.isEmpty ? .empty : .content
    }
    
    @MainActor private func update(err: Error) {
        state = .failed
    }
}

struct ProfilePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Preview todo")
        }
    }
}
