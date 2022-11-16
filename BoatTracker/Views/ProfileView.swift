import Foundation
import SwiftUI

struct ProfileView: View {
    let info: ProfileInfo
    @ObservedObject var vm: ProfileVM
    
    var color: BoatColor { BoatColor.shared }
    var lang: Lang { info.lang }
    
    var body: some View {
        List {
            Section(footer: Footer()) {
                if let summary = vm.summary {
                    TrackSummaryView(track: summary, lang: lang)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if vm.state == .empty {
                    Text(info.lang.messages.noSavedTracks)
                        .foregroundColor(color.secondaryText)
                } else if vm.state == .loading {
                    ProgressView()
                }
            }
            Section(footer: Footer()) {
                if let summary = vm.summary {
                    NavigationLink {
                        ChartsRepresentable(track: summary.trackName, lang: lang)
                            .navigationBarTitleDisplayMode(.large)
                            .navigationTitle(summary.trackTitle?.description ?? summary.startDate)
                    } label: {
                        Text(lang.track.graph)
                    }
                }
                NavigationLink {
                    TrackListRepresentable(delegate: vm.tracksDelegate, login: false, lang: lang)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.track.tracks)
                } label: {
                    Text(lang.track.trackHistory)
                }
                NavigationLink {
                    StatsRepresentable(lang: lang)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.labels.statistics)
                } label: {
                    Text(lang.labels.statistics)
                }
                NavigationLink {
                    BoatTokensView(lang: TokensLang.build(lang: lang), vm: BoatTokensVM.shared)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.track.boats)
                } label: {
                    Text(lang.track.boats)
                }
            }
            Section(footer: Footer()) {
                NavigationLink {
                    SelectLanguageView(lang: lang.profile.languages, vm: LanguageVM())
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.profile.language)
                } label: {
                    Text(lang.profile.language)
                }
            }
            Section(footer: Footer()) {
                NavigationLink {
                    AttributionsView(info: lang.attributions)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(lang.attributions.title)
                } label: {
                    Text(lang.attributions.title)
                }
            }
            Section(footer: Footer()) {
                if let versionText = vm.versionText(lang: lang) {
                    Text(versionText)
                        .foregroundColor(color.lightGray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text("\(lang.profile.signedInAs) \(info.user.email)")
                    .foregroundColor(color.lightGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }.task {
            await vm.loadTracks()
        }
        .listStyle(.plain)
    }
    func Footer() -> some View {
        Spacer()
    }
}

struct ProfilePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Preview todo")
        }
    }
}
