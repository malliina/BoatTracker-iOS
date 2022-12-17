import Foundation
import SwiftUI

struct ProfileInfo: Identifiable {
    let user: UserToken
    let current: TrackName?
    let lang: Lang
    var id: String { user.email }
}

struct ProfileView: View {
    let log = LoggerFactory.shared.view(ProfileView.self)
    @Environment(\.dismiss) var dismiss
    let info: ProfileInfo
    @StateObject var vm: ProfileVM = ProfileVM()
    
    var lang: Lang { info.lang }
    var summaryLang: SummaryLang { SummaryLang.build(lang) }
    var profileLang: ProfileLang { lang.profile }
    var modules: Modules { vm.modules }
    
    @State var showDeleteConfirmation = false
    @State var confirm = false
    @State var confirmed = false
    @State var vc: UIViewController? = nil

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
                    SelectLanguageView(lang: profileLang.languages, vm: modules.languages)
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
                Text("\(profileLang.signedInAs) \(info.user.email)")
                    .foregroundColor(color.lightGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                if let versionText = vm.versionText(lang: lang) {
                    Text(versionText)
                        .foregroundColor(color.lightGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            BoatSection {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        Task {
                            if let vc = vc {
                                await vm.signOut(from: vc)
                                dismiss()
                            }
                        }
                    } label: {
                        Text(profileLang.logout)
                    }
                    Spacer()
                }
            }
            BoatSection {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        showDeleteConfirmation.toggle()
                    } label: {
                        Text(profileLang.deleteAccount)
                    }
                    .confirmationDialog(profileLang.deleteAccountConfirmation, isPresented: $showDeleteConfirmation, titleVisibility: .visible, presenting: info.user.email) { email in
                        Button(profileLang.deleteAccount, role: .destructive) {
                            Task {
                                if let vc = vc {
                                    let success = await vm.deleteMe(from: vc)
                                    if success {
                                        dismiss()
                                    }
                                }
                            }
                        }
                    } message: { email in
                        Text("\(profileLang.signedInAs) \(email)")
                    }
                    Spacer()
                }
            }
        }
        .background {
            ControllerRepresentable(vc: $vc)
        }
        .task {
            await vm.loadTracks(latest: info.current)
        }
    }
    
    func BoatSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Section {
            content()
        } footer: {
            Spacer()
        }
        .listRowSeparator(.hidden)
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
    
    func signOut(from: UIViewController) async {
        log.info("Signing out...")
        await Auth.shared.signOut(from: from)
    }
    
    func deleteMe(from: UIViewController) async -> Bool {
        do {
            _ = try await http.deleteMe()
            log.info("Deleted user.")
            await signOut(from: from)
            return true
        } catch {
            log.error("Failed to delete user. \(error)")
            return false
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
