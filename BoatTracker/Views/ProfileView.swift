import Foundation
import MapboxMaps
import SwiftUI

struct ProfileInfo: Identifiable {
  let user: UserToken
  let current: TrackName?
  let lang: Lang
  var id: String { user.email }
}

struct ProfileView<T>: View where T: ProfileProtocol {
  let log = LoggerFactory.shared.view(ProfileView.self)
  @Environment(\.dismiss) var dismiss
  let info: ProfileInfo
  @EnvironmentObject var vm: T
  @EnvironmentObject var activeTrack: ActiveTrack

  var lang: Lang { info.lang }
  var summaryLang: SummaryLang { SummaryLang.build(lang) }
  var profileLang: ProfileLang { lang.profile }

  @State var showDeleteConfirmation = false
  @State var confirm = false
  @State var confirmed = false
  @State var vc: UIViewController? = nil

  var body: some View {
    BoatList {
      BoatSection {
        if vm.state == .loading {
          ZStack {
            TrackSummaryView(track: ProfileVM.emptySummary, lang: summaryLang)
              .frame(maxWidth: .infinity, alignment: .center)
              .opacity(0)
            LoadingView()
          }
        } else if let summary = vm.summary, vm.state == .content {
          TrackSummaryView(track: summary, lang: summaryLang)
            .frame(maxWidth: .infinity, alignment: .center)
        } else if vm.state == .empty {
          Text(lang.messages.noSavedTracks)
            .foregroundColor(color.secondaryText)
        } else if vm.state == .failed {
          Text(lang.messages.failedToLoadProfile)
        } else {
          Text("")
        }
      }
      BoatSection {
        NavigationLink {
          if let summary = vm.summary {
            ChartsView(
              lang: ChartLang.build(lang),
              title: summary.trackTitle?.description ?? summary.startDate,
              trackName: summary.trackName)
          } else {
            ChartsView(
              lang: ChartLang.build(lang),
              title: "",
              trackName: TrackName(""))
          }
        } label: {
          Text(lang.track.graph)
        }.disabled(vm.summary == nil)
        NavigationLink {
          TracksView<TracksViewModel>(lang: summaryLang, activeTrack: activeTrack) {
            dismiss()
          }
        } label: {
          Text(lang.track.trackHistory)
        }
        NavigationLink {
          StatsView<StatsViewModel>(lang: lang)
        } label: {
          Text(lang.labels.statistics)
        }
        NavigationLink {
          BoatTokensView<BoatTokensVM>(lang: TokensLang.build(lang: lang))
        } label: {
          Text(lang.track.boats)
        }
      }
      BoatSection {
        NavigationLink {
          SelectLanguageView<LanguageVM>(lang: profileLang.languages)
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
          .confirmationDialog(
            profileLang.deleteAccountConfirmation, isPresented: $showDeleteConfirmation,
            titleVisibility: .visible, presenting: info.user.email
          ) { email in
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
    .onDisappear {
      vm.disconnect()
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

struct ProfilePreviews: PreviewProvider {
  static let previewTrack = ProfileVM.emptySummary
  class PreviewsVM: ProfileProtocol {
    let state: ViewState
    let summary: TrackInfo?

    init(state: ViewState, summary: TrackInfo?) {
      self.state = state
      self.summary = summary
    }

    func versionText(lang: Lang) -> String? {
      "Version preview"
    }

    func loadTracks(latest: TrackName?) async {
    }

    func disconnect() {
    }

    func signOut(from: UIViewController) async {
    }

    func deleteMe(from: UIViewController) async -> Bool {
      false
    }
  }

  static var previews: some View {
    ForEach(BoatPreviews.shared.devices, id: \.self) { deviceName in
      Group {
        ProfileView<PreviewsVM>(
          info: ProfileInfo(
            user: UserToken(email: "a@b.com", token: AccessToken("abc")), current: nil, lang: lang)
        )
        .environmentObject(PreviewsVM(state: .content, summary: previewTrack))
        .environmentObject(ActiveTrack())
        ProfileView<PreviewsVM>(
          info: ProfileInfo(
            user: UserToken(email: "a@b.com", token: AccessToken("abc")), current: nil, lang: lang)
        )
        .environmentObject(PreviewsVM(state: .loading, summary: nil))
        .environmentObject(ActiveTrack())
      }
      .previewDevice(PreviewDevice(rawValue: deviceName))
      .previewDisplayName(deviceName)
    }
  }
}
