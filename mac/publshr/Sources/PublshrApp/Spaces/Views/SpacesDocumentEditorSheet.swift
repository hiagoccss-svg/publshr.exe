import SwiftUI

struct SpacesDocumentEditorSheet: View {
    @ObservedObject var spaces: SpacesViewModel
    let document: SpaceDocumentRecord
    @State private var title: String
    @State private var content: String
    @Environment(\.dismiss) private var dismiss

    init(spaces: SpacesViewModel, document: SpaceDocumentRecord) {
        self.spaces = spaces
        self.document = document
        _title = State(initialValue: document.title)
        _content = State(initialValue: document.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Document")
                .font(.title2.weight(.semibold))
                .padding(.bottom, 12)

            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .font(.system(size: 13))
                    .frame(minHeight: 280)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    spaces.editingDocument = nil
                    dismiss()
                }
                Button("Save") {
                    Task {
                        await spaces.saveDocument(document, title: title, content: content)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .frame(width: 520, height: 480)
    }
}
