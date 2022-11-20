import Foundation
import SwiftUI

struct EditDialog: View {
    @Environment(\.dismiss) var dismiss
    
    let navTitle: String
    let title: String
    let message: String
    let initialValue: String
    let ctaTitle: String
    let cancel: String
    
    let onSave: (String) async -> Void
    
    @State var newName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text(message)
                TextField(title, text: $newName)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Button(ctaTitle) {
                    Task {
                        await onSave(newName)
                        dismiss()
                    }
                }
                .padding()
                .disabled(newName.isEmpty || newName == initialValue)
                .buttonStyle(.bordered)
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
        .onAppear {
            newName = initialValue
        }
    }
}

struct EditDialogPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            EditDialog(navTitle: "Edit", title: "Some title", message: "Edit here below", initialValue: "", ctaTitle: "Save", cancel: "Cancel") { _ in
            }
        }
    }
}

