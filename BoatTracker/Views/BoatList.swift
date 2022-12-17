import Foundation
import SwiftUI

func BoatList<Content: View>(rowSeparator: Visibility = .hidden, @ViewBuilder content: () -> Content) -> some View {
    List {
        content()
            .listRowSeparator(rowSeparator)
            
    }
    .listStyle(.plain)
    .frame( maxWidth: .infinity)
}
