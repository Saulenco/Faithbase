//
//  AppointmentView.swift
//  Faithbase
//
//  Created by Paniti Marta on 2024. 10. 26..
//

import SwiftUI

struct AppointmentView: View {
    @Environment(\.colorScheme) var colorScheme // Detect light or dark mode
    let description: String
    let medic: Medic
    
    var body: some View {
        HStack {
            VStack(spacing: 16) {
                // Description field
                Text(description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Divider()
                    .padding(.horizontal)
                
                // Medic field
                VStack(spacing: 8) {
                    Text(medic.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(medic.speciality)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // Action for calling medic's phone number
                        if let phoneURL = URL(string: "tel://\(medic.phone)") {
                            UIApplication.shared.open(phoneURL)
                        }
                    }) {
                        Text("Make an Appointment")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                }
                .padding()
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(radius: 5)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8,
                   alignment: .leading)
        }
    }
}

#Preview {
    AppointmentView(description: "Description of the appointment or details about the medic.",
                    medic: Medic(name: "John Doe",
                                 phone: "123124",
                                 availability: true,
                                 speciality: "Cardiology"))
}
