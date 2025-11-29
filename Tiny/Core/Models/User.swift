//
//  User.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case mother
    case father
}

struct User: Codable, Identifiable {
    var id: String?
    var email: String
    var name: String?
    var role: UserRole?
    var pregnancyWeeks: Int?
    var roomCode: String?
    var createdAt: Date
    
    init(id: String? = nil,
         email: String,
         name: String? = nil,
         role: UserRole? = nil,
         pregnancyWeeks: Int? = nil,
         roomCode: String? = nil,
         createdAt: Date) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.pregnancyWeeks = pregnancyWeeks
        self.roomCode = roomCode
        self.createdAt = createdAt
    }
}
