import Foundation
import SwiftUI

struct ProfileView: View {
    let info: ProfileInfo
    @ObservedObject var vm: ProfileVM
    
    var color: BoatColor { BoatColor.shared }
    var lang: Lang { info.lang }
    
    var body: some View {
        VStack {
            if let summary = vm.summary {
                TrackSummaryView(track: summary, lang: lang)
            } else if vm.state == .empty {
                Text(info.lang.messages.noSavedTracks)
                    .foregroundColor(color.secondaryText)
            } else if vm.state == .loading {
                ProgressView()
            }
            if let summary = vm.summary {
                NavigationLink {
                    ChartsRepresentable(track: summary.trackName, lang: lang)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle(summary.trackTitle?.description ?? summary.startDate)
                } label: {
                    NavLink(title: lang.track.graph)
                }.padding()
            }
            NavigationLink {
                TrackListRepresentable(delegate: vm.tracksDelegate, login: false, lang: lang)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(lang.track.tracks)
            } label: {
                NavLink(title: lang.track.trackHistory)
            }.padding()
            NavigationLink {
                StatsRepresentable(lang: lang)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(lang.labels.statistics)
            } label: {
                NavLink(title: lang.labels.statistics)
            }.padding()
            NavigationLink {
                BoatTokensRepresentable(lang: lang)
                    .navigationBarTitleDisplayMode(.large)
                    .navigationTitle(lang.track.boats)
            } label: {
                NavLink(title: lang.track.boats)
            }.padding()
            Spacer()
        }.task {
            await vm.loadTracks()
        }
    }
}

struct ProfilePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Preview todo")
        }
    }
}
