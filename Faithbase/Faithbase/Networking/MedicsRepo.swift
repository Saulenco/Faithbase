//
//  MedicsRepo.swift
//  Faithbase
//
//  Created by Constantin Saulenco on 10/26/24.
//

import Foundation

final class MedicsRepo {
    
    class func getMedics(_ query: String) -> Medic? {
        let medics = findMedics(for: query)
        return medics?.first
    }
    
    private class func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Count = s1.count
        let s2Count = s2.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)
        
        for i in 0...s1Count {
            matrix[i][0] = i
        }
        
        for j in 0...s2Count {
            matrix[0][j] = j
        }
        
        for (i, s1Char) in s1.enumerated() {
            for (j, s2Char) in s2.enumerated() {
                if s1Char == s2Char {
                    matrix[i + 1][j + 1] = matrix[i][j]
                } else {
                    matrix[i + 1][j + 1] = min(matrix[i][j], matrix[i + 1][j], matrix[i][j + 1]) + 1
                }
            }
        }
        
        return matrix[s1Count][s2Count]
    }
    
    private class func similarityPercentage(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1.lowercased(), s2.lowercased())
        let maxLength = max(s1.count, s2.count)
        return (1.0 - (Double(distance) / Double(maxLength))) * 100
    }
    
    private class func findMedics(for partialName: String) -> [Medic]? {
        // Load the Medics.plist file
        guard let path = Bundle.main.path(forResource: "Medics", ofType: "plist"),
              let data = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Could not load Medics.plist")
            return nil
        }

        var matches = data.keys.compactMap{ specialty in
            return  (specialty, similarityPercentage(partialName, specialty))
        }

        matches = matches.sorted(by: { $0.1 > $1.1 })


        var matchedSpecialty = "Primary Care"
        // Find the closest matching specialty
        if let firstMatch = matches.first, firstMatch.1 > 70 {
            matchedSpecialty = firstMatch.0
        }

        // Extract medics for the matched specialty
        guard let medicsArray = data[matchedSpecialty] as? [[String: Any]] else {
            print("Error reading medics for specialty: \(matchedSpecialty)")
            return nil
        }
        
        // Convert data to Medic objects
        let medics = medicsArray.compactMap { medicDict -> Medic? in
            guard let name = medicDict["Name"] as? String,
                  let phone = medicDict["Phone"] as? String,
                  let availability = medicDict["Availability"] as? Bool else {
                return nil
            }
            return Medic(name: name, phone: phone, availability: availability, speciality: matchedSpecialty)
        }
        
        return medics
    }
}
