//
//  SavedMomentModel.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 30/11/25.
//

import SwiftData
import Foundation

@Model
class SavedMoment {
    @Attribute(.unique) var id: UUID
    var filePath: String // Local file path for the image
    var timestamp: Date
    var pregnancyWeeks: Int?
    
    // Firebase fields
    var firebaseId: String?
    var motherUserId: String?
    var roomCode: String?
    var isShared: Bool
    var firebaseStorageURL: String?
    var isSyncedToCloud: Bool
    
    init(filePath: String,
         timestamp: Date = Date(),
         pregnancyWeeks: Int? = nil,
         firebaseId: String? = nil,
         motherUserId: String? = nil,
         roomCode: String? = nil,
         isShared: Bool = true,
         firebaseStorageURL: String? = nil,
         isSyncedToCloud: Bool = false) {
        self.id = UUID()
        self.filePath = filePath
        self.timestamp = timestamp
        self.pregnancyWeeks = pregnancyWeeks
        self.firebaseId = firebaseId
        self.motherUserId = motherUserId
        self.roomCode = roomCode
        self.isShared = isShared
        self.firebaseStorageURL = firebaseStorageURL
        self.isSyncedToCloud = isSyncedToCloud
    }
}
