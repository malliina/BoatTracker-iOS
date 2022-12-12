import Foundation
import SwiftUI

struct DeleteDialog: View {
    @Environment(\.dismiss) var dismiss
    
    let navTitle: String
    let message: String
    let confirmation: String
    let ctaTitle: String
    let cancel: String
    
    let onConfirm: (UIViewController) async -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text(message)
                    .padding()
                Text(confirmation)
                    .padding()
                ViewControllerButton(ctaTitle, style: .bordered) { from in
                    await onConfirm(from)
                    dismiss()
                }
                    .padding()
                    .frame(height: 42)
                Spacer()
            }
            .navigationTitle(navTitle)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DeleteDialogPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            DeleteDialog(navTitle: "Delete account", message: "You are santa@claus.com", confirmation: "Are you sure?", ctaTitle: "Delete", cancel: "Cancel") { vc in
            }
        }
    }
}

