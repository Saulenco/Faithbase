//
//  Untitled.swift
//  Faithbase
//
//  Created by Constantin Saulenco on 10/26/24.
//

import Foundation

struct OpenAIResponse: Codable {
    let message: String
    let speciality: String
}

class Endpoint {

    func makeOpenAIRequest(prompt: String, completion: @escaping (OpenAIResponse?) -> Void) {
        let apiKey = "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"
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",  // Adjust model as needed
            "messages": [
                ["role": "user", "content": prompt]  // Pass the prompt as user content
            ],
            "temperature": 0.2,
            "max_tokens": 200
        ]

        // Convert the body to JSON
        let jsonData = try? JSONSerialization.data(withJSONObject: requestBody)

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            // Decode the response JSON
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {

                // Attempt to parse JSON within the response's content
                            if let responseData = content.data(using: .utf8) {
                                do {
                                    let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: responseData)
                                    completion(openAIResponse)
                                } catch {
                                    print("Failed to parse message content: \(error)")
                                    completion(nil)
                                }
                            } else {
                                print("Failed to convert content to data")
                                completion(nil)
                            }

            } else {
                print("Failed to decode response")
                completion(nil)
            }
        }

        task.resume()
    }

}
