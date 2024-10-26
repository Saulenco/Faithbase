//
//  DocumentPicker.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 27..
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import NaturalLanguage

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedDocumentText: String

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.plainText, UTType.text])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Extract text based on file type
            if url.pathExtension.lowercased() == "pdf" {
                let text = extractTextFromPDF(url: url) ?? ""
                parent.selectedDocumentText = text
            } else if url.pathExtension.lowercased() == "txt" {
                let text = extractTextFromTXT(url: url) ?? ""
                parent.selectedDocumentText = text
            } else {
                parent.selectedDocumentText = ""
            }
        }
        
        private func extractTextFromPDF(url: URL) -> String? {
            guard let pdfDocument = PDFDocument(url: url) else { return nil }
            var text = ""
            for pageIndex in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    text += page.string ?? ""
                }
            }
            return text
        }

        private func extractTextFromTXT(url: URL) -> String? {
            do {
                return try String(contentsOf: url, encoding: .utf8)
            } catch {
                print("Error reading TXT file: \(error)")
                return nil
            }
        }
        
        func extractEntities(text: String) -> String {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = text
            var formattedText: [String] = []
            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
                if let tag = tag {
                    let formatted = "\(text[range]): \(tag.rawValue)"
                    formattedText.append(formatted)
                }
                return true
            }
            return formattedText.isEmpty ? text : formattedText.joined(separator: ", ")
        }
    }
}
