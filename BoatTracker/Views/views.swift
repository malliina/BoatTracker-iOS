import Foundation
import SwiftUI

struct NavLink: View {
  let title: String

  var body: some View {
    HStack {
      Text(title)
      Spacer()
      Image(systemName: "chevron.right")
    }
  }
}

enum ViewState {
  case empty
  case content
  case loading
  case failed
  case idle
}

enum StatBoxStyle {
  case small
  case large
}
