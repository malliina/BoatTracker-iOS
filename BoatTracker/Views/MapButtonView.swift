import Foundation
import SwiftUI
import UIKit

struct MapButtonView: View {
  let imageResource: String
  let action: () -> Void
  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: imageResource)
        .resizable()
        .scaledToFit()
        .frame(width: 22, height: 22)
    }
    .frame(width: 36, height: 36)
    .background(.white)
    .cornerRadius(2)
  }
}
