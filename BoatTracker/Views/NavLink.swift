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
