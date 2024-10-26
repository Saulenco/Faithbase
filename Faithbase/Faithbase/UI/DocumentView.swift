//
//  DocumentView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 27..
//

import SwiftUI

struct DocumentView: View {
    let documentName: String

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 16) {
                // Document icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.teal)
                
                Text(documentName)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.teal, lineWidth: 2)
            )
            .shadow(radius: 5)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
               alignment: .trailing)
    }
}


#Preview {
    DocumentView(documentName: "Template.pdf")
}
