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
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(CursorTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Document")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                    Text(spaces.selectedSpace?.name ?? "Space")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                Spacer()
            }
            .padding(.bottom, 16)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 10)

            Text("Content")
                .font(SpacesClickUpDesign.sectionLabelFont)
                .foregroundStyle(CursorTheme.foregroundDim)
                .padding(.bottom, 6)

            TextEditor(text: $content)
                .font(.system(size: 13))
                .frame(minHeight: 300)
                .padding(10)
                .background(CursorTheme.panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: SpacesClickUpDesign.docRowRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: SpacesClickUpDesign.docRowRadius)
                        .strokeBorder(CursorTheme.borderSubtle, lineWidth: 1)
                )

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
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 20)
        }
        .padding(24)
        .frame(width: 560, height: 520)
    }
}
