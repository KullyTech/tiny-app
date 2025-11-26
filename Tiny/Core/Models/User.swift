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
    @DocumentID var id: String?
    var email: String
    var name: String?
    var role: UserRole?
    var pregnancyMonths: Int?
    var roomCode: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, role, pregnancyMonths, roomCode, createdAt
    }
}
