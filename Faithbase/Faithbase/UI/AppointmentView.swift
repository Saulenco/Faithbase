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
            Spacer()
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
                    
                    Text("")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // Action for appointment
                        print("Make an appointment tapped")
                    }) {
                        Text("Make an Appointment")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                
                .padding()
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
            .cornerRadius(16)
            .shadow(radius: 5)
            .padding()
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7,
                   alignment: .trailing)
        }
    }
}

#Preview {
    AppointmentView(description: "Description of the appointment or details about the medic.",
                    medic: Medic(name: "John Doe", phone: "123124", availability: true, speciality: "Cardiology"))
}
