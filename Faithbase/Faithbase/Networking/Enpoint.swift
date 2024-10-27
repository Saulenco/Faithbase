//
//  Untitled.swift
//  Faithbase
//
//  Created by Constantin Saulenco on 10/26/24.
//

import CoreML
import Foundation

struct OpenAIResponse: Decodable {
    let message: String
    let speciality: String?
    let missing_information: String?
}

class Endpoint {
    
    func getSpeciality(from symptoms: String) -> String? {
        // Load the model
        guard let model = try? SpecialtyClassifier(configuration: MLModelConfiguration()) else {
            print("Failed to load model")
            return nil
        }
        
        // Make a prediction
        do {
            let prediction = try model.prediction(text: symptoms)
            return prediction.label
        } catch {
            print("Prediction error: \(error)")
            return nil
        }
    }
    
    func makeOpenAIRequest(for messages: [Message], completion: @escaping (OpenAIResponse?) -> Void) {

        // Construct the conversation history for the prompt
        var conversationHistory = "This is an ongoing conversation between a user seeking medical advice and an AI medical assistant. The assistant's goal is to understand the user's symptoms fully, analyze their relevance, and provide guidance on the appropriate specialist if enough information is available.\n\nConversation:\n"
        var userSymptoms = ""
        for msg in messages {
            let role = msg.isUser ? "User" : "AI"
            conversationHistory += "\(role): \(msg.text)\n"

            if msg.isUser {
                userSymptoms += "\(userSymptoms.isEmpty ? "" : ", ")\(msg.text)\n"
            }
        }

        let prompt = """
               \(conversationHistory)
               
               Instructions for the AI:
               - Carefully analyze the conversation history to determine if the user has provided sufficient medically relevant information, such as symptoms, duration, intensity, location, and any other necessary context.
               - Only if the provided information is incomplete or unclear should the assistant ask for additional specific details. Avoid asking unnecessary questions if the input already includes enough detail for an accurate recommendation.
               - If there is enough information, recommend an appropriate specialist in the following JSON format:

               {
                 "message": "Based on your symptoms, it would be best to consult a [specialist type].",
                 "speciality": "[specialist type]"
               }
               where speciality can be: Cardiology, Dermatology, Neurology, Orthopedics, Pediatrics, Ophthalmology, Endocrinology, Gastroenterology, Psychiatry, Oncology, Urology,, Infectious Diseases, Hematology, Primary Care
               
               - If additional information is truly necessary, identify the missing information and ask a specific follow-up question in the following JSON format. Ensure the question is clear, concise, and directly relevant to making an accurate recommendation:

               {
                 "message": "Could you provide more information on [missing information]? For example, [example question based on context].",
                 "missing_information": "[missing category]"
               }

               Guidelines for determining when additional information is needed:
               - For pain: If location, severity, or duration is unclear, request these specifics. Otherwise, proceed with the available information.
               - For fatigue: If the duration, severity, or impact on daily activities is missing, ask about these aspects. Do not ask if these are already covered.
               - For respiratory issues: If relevant details like shortness of breath, cough type, or duration are missing, request them. Avoid redundancy if covered.
               - For digestive issues: Ask about nausea, vomiting, or specific triggers only if not mentioned by the user.

               The goal is to minimize repetitive or redundant questions while ensuring the assistant gathers enough information to make an informed recommendation.
               """


        let apiKey = "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"
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",  // Adjust model as needed
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2,
            "max_tokens": 200
        ]
        
        // Convert the body to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize request body to JSON")
            completion(nil)
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                completion(nil)
                return
            }
            
            let response = self.parseOpenAIResponse(data: data)
            if let speciality = response?.speciality {
                self.saveSymptomsData(symptoms: userSymptoms, medicalSpeciality: speciality)
            }

            completion(response)
        }
        
        task.resume()
    }

    private func parseOpenAIResponse(data: Data) -> OpenAIResponse? {
        // Decode the response JSON from OpenAI
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            // Attempt to parse JSON from OpenAI response content
            if let responseData = content.data(using: .utf8) {
                do {
                    let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: responseData)
                    return openAIResponse
                } catch {
                    print("Failed to parse OpenAI response content as OpenAIResponse object: \(error)")
                    
                    // If JSON parsing fails, assume content is a plain text message and create a default response
                    let fallbackResponse = OpenAIResponse(message: content, speciality: nil, missing_information: nil)
                    return fallbackResponse
                }
            } else {
                print("Failed to convert content to data")
            }
            
        } else {
            print("Failed to decode response JSON")
        }

        return nil
    }

    // Define a function to save symptoms data to a .plist file
    private func saveSymptomsData(symptoms: String, medicalSpeciality: String) {
        // Get the URL of the document directory
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access the documents directory")
            return
        }

        // Define the path for symptoms.plist
        let fileURL = documentsURL.appendingPathComponent("symptoms.plist")

        // Load existing data if file exists, otherwise create a new array
        var existingData: [[String: Any]] = []

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                if let loadedData = try PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]] {
                    existingData = loadedData
                }
            } catch {
                print("Error loading existing data from plist: \(error)")
            }
        }

        // Append the new data
        let newEntry: [String: Any] = [
            "symptoms": symptoms,
            "medicalSpeciality": medicalSpeciality
        ]
        existingData.append(newEntry)

        // Save the updated array back to the file
        do {
            let plistData = try PropertyListSerialization.data(fromPropertyList: existingData, format: .xml, options: 0)
            try plistData.write(to: fileURL)
            print("Data saved successfully at \(fileURL)")
        } catch {
            print("Error saving data to plist: \(error)")
        }
    }
}
