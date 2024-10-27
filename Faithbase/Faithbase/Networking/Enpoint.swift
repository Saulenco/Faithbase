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
    
    func makeOpenAIRequest(prompt: String, completion: @escaping (OpenAIResponse?) -> Void) {
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
            
            self.parseOpenAIResponse(data: data, completion: completion)
        }
        
        task.resume()
    }

    func parseOpenAIResponse(data: Data, completion: @escaping (OpenAIResponse?) -> Void) {
        // Decode the response JSON from OpenAI
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            // Attempt to parse JSON from OpenAI response content
            if let responseData = content.data(using: .utf8) {
                do {
                    let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: responseData)
                    completion(openAIResponse)
                } catch {
                    print("Failed to parse OpenAI response content as OpenAIResponse object: \(error)")
                    
                    // If JSON parsing fails, assume content is a plain text message and create a default response
                    let fallbackResponse = OpenAIResponse(message: content, speciality: nil, missing_information: nil)
                    completion(fallbackResponse)
                }
            } else {
                print("Failed to convert content to data")
                completion(nil)
            }
            
        } else {
            print("Failed to decode response JSON")
            completion(nil)
        }
    }
}
