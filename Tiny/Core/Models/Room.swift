//
//  Room.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import Foundation
import FirebaseFirestore

struct Room: Identifiable, Codable {
    @DocumentID var id: String?
    var code: String
    var motherUserId: String
    var fatherUserId: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, code, motherUserId, fatherUserId, createdAt
    }
    
}
