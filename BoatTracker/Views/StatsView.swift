import Foundation
import SwiftUI

struct StatsView<T>: View where T: StatsProtocol {
  private let log = LoggerFactory.shared.vc(StatsView.self)
  let lang: Lang
  @EnvironmentObject var vm: T

  var body: some View {
    statefulView(state: vm.state)
      .task {
        await vm.load()
      }
      .navigationBarTitleDisplayMode(.large)
      .navigationTitle(lang.labels.statistics)
  }

  @ViewBuilder
  private func statefulView(state: ViewState) -> some View {
    switch state {
    case .loading:
      LoadingView()
    case .content:
      listView()
    default:
      Text("")
    }
  }

  private func listView() -> some View {
    BoatList(rowSeparator: .automatic) {
      if let stats = vm.stats {
        ForEach(stats.yearly, id: \.year.value) { yearly in
          Section {
            ForEach(yearly.monthly, id: \.id) { monthly in
              PeriodStatView(stat: monthly, lang: PeriodStatLang.build(lang))
            }
          } header: {
            PeriodStatView(stat: yearly, lang: PeriodStatLang.build(lang))
          }
        }
        if stats.isEmpty {
          Text(lang.messages.noSavedTracks)
            .foregroundColor(color.secondaryText)
        }
      }
    }
  }
}

struct StatsPreview: BoatPreviewProvider, PreviewProvider {
  class PreviewsVM: StatsProtocol {
    var state: ViewState = .content
    var stats: StatsResponse? {
      StatsResponse(
        allTime: Stats(
          from: DateVal("today"), to: DateVal("tomorrow"), days: 32,
          trackCount: 12,
          distance: 10.meters, duration: 42.seconds),
        yearly: [
          YearlyStats(
            year: YearVal(2023), days: 13, trackCount: 155,
            distance: 2000.meters,
            duration: 53.seconds,
            monthly: [
              MonthlyStats(
                label: "June", year: YearVal(2023), month: MonthVal(6),
                days: 11, trackCount: 16,
                distance: 1000.meters, duration: 101.seconds),
              MonthlyStats(
                label: "July", year: YearVal(2023), month: MonthVal(7),
                days: 13, trackCount: 16,
                distance: 12110.meters, duration: 504.seconds),
            ])
        ])
    }

    func load() async {
    }
  }

  static var preview: some View {
    StatsView<PreviewsVM>(lang: lang).environmentObject(PreviewsVM())
  }
}

protocol StatsProtocol: ObservableObject {
  var state: ViewState { get }
  var stats: StatsResponse? { get }
  func load() async
}

class StatsViewModel: StatsProtocol {
  private let log = LoggerFactory.shared.vc(StatsViewModel.self)

  @Published var state: ViewState = .idle
  @Published var stats: StatsResponse?

  func load() async {
    await update(state: .loading)
    do {
      await update(stats: try await http.stats())
    } catch {
      log.info("Failed to load profile. \(error.describe)")
      await update(error: error)
    }
  }

  @MainActor private func update(stats: StatsResponse) {
    self.stats = stats
    state = .content
  }

  @MainActor private func update(error: Error) {
    state = .failed
  }

  @MainActor private func update(state: ViewState) {
    self.state = state
  }
}
