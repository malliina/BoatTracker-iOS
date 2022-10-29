import Foundation
import SwiftUI

struct MainMapView: View {
    let log = LoggerFactory.shared.view(MainMapView.self)
    
    @ObservedObject var viewModel: MapViewModel
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                SwiftUIMapView(styleUri: $viewModel.styleUri)
                    .ignoresSafeArea()
                Button {
                    log.info("Profile tapped")
                } label: {
                    Image(uiImage: #imageLiteral(resourceName: "SettingsSlider"))
                }
                .padding()
                .background(.white)
                .opacity(0.6)
                .cornerRadius(2)
                .offset(x: 20, y: 20)
                .frame(width: 40, height: 40)
            }
        }
    }
}

class Model: ObservableObject {
    @Published var message: String = ""
    
    func update() {
        message = "Hej"
        print("Set message to \(message).")
    }
}

struct MainView2: View {
    @ObservedObject var model = Model()
    var body: some View {
        HStack {
            Button {
                model.update()
            } label: {
                Text("Prep")
            }

            Text("Message is \(model.message)").onAppear {
                model.update()
            }
        }
    }
}

class Stopwatch: ObservableObject {
    // 2.
    @Published var counter: Int = 0
    @Published var message: String = "no message yet"
    
    var timer = Timer()
    
    func prep() {
        message = "Hejsan"
    }
    
    // 3.
    func start() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.counter += 1
        }
    }
    
    // 4.
    func stop() {
        timer.invalidate()
    }
    
    // 5.
    func reset() {
        counter = 0
        timer.invalidate()
    }
}

struct ContentView: View {
    // 1.
    @ObservedObject var stopwatch = Stopwatch()
    
    var body: some View {
        VStack {
            HStack {
                Text("Message is \(stopwatch.message)").onAppear {
                    stopwatch.prep()
                }
                // 2.
                Button(action: {
                    self.stopwatch.prep()
                }) {
                    Text("Message")
                }
                Button(action: {
                    self.stopwatch.start()
                }) {
                    Text("Start")
                }
                
                Button(action: {
                    self.stopwatch.stop()
                }) {
                    Text("Stop")
                }
                Button(action: {
                    self.stopwatch.reset()
                }) {
                    Text("Reset")
                }
            }
            // 3.
            Text("\(self.stopwatch.counter)")
        }.font(.largeTitle)
    }
}
