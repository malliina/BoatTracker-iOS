import Foundation
import SwiftUI

func BoatList<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    List {
        content()
            .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
}
