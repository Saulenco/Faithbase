//
//  Medic.swift
//  Faithbase
//
//  Created by Constantin Saulenco on 10/26/24.
//

final class Medic: Codable {
    let name: String
    let phone: String
    let availability: Bool

    init(name: String, phone: String, availability: Bool) {
        self.name = name
        self.phone = phone
        self.availability = availability
    }
}