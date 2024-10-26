//
//  ContentView.swift
//  Faithbase
//
//  Created by Constantin Saulenco on 10/26/24.
//

import SwiftUI

struct ContentView: View {
    let endpoint = Endpoint()
    @State var reply: String = ""
    @State var medic: String = ""

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(reply)
            Text(medic)
            Button("Get recommendation") {
                getMedic()
            }
        }
        .padding()
    }

    private func getMedic() {

        let symptoms = "I have been experiencing persistent headaches, dizziness, and occasional numbness in my hands."

        if let speciality = endpoint.getSpeciality(from: symptoms),
              let medicFound = MedicsRepo.getMedics(speciality)  {
            self.medic = medicFound.name
            return
        }


        let prompt = """
        The user will provide a description of their symptoms. Please respond by recommending the type of medical specialist they should consult, using the json format:
        "{message: Based on your symptoms, it would be best to consult a [specialist type],
           speciality: speciality
         }".

        Consider common medical specialties, such as cardiology, dermatology, gastroenterology, neurology, orthopedics, and psychiatry, and choose the one that best fits the user's symptoms.

        User's Symptoms: \(symptoms)
        """

        endpoint.makeOpenAIRequest(prompt: prompt) { response in
            self.reply = response?.message ?? ""
            let medic = MedicsRepo.getMedics(response?.speciality ?? "")
            self.medic = medic?.name ?? "Not found"
        }
    }
}

#Preview {
    ContentView()
}
