import Foundation
import SwiftUI

struct StatsView: View {
    private let log = LoggerFactory.shared.vc(StatsView.self)
    let lang: Lang
    @ObservedObject var vm: StatsViewModel
    
    var body: some View {
        NavigationView {
            List {
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
                }
            }
            .listStyle(.plain)
            .task {
                await vm.load()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(lang.labels.statistics)
    }
}

class StatsViewModel: ObservableObject {
    private let log = LoggerFactory.shared.vc(StatsViewModel.self)
    @Published var stats: StatsResponse?
    @Published var error: Error?
    
    func load() async {
        do {
            await update(stats: try await http.stats())
        } catch {
            log.info("Failed to load profile. \(error.describe)")
            await update(error: error)
        }
    }
    
    @MainActor private func update(stats: StatsResponse) {
        self.stats = stats
    }
    
    @MainActor private func update(error: Error) {
        self.error = error
    }
}

extension ObservableObject {
    var http: BoatHttpClient { Backend.shared.http }
}

extension View {
    var color: BoatColor { BoatColor.shared }
}
