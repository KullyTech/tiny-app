//
//  SavedHeartbeatModel.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 20/11/25.
//

import SwiftData
import Foundation

@Model
class SavedHeartbeat {
    @Attribute(.unique) var id: UUID
    var filePath: String
    var timestamp: Date

    init(filePath: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.filePath = filePath
        self.timestamp = timestamp
    }
}
