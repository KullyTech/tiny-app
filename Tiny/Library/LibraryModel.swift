//
//  LibraryModel.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 02/11/25.
//

import Foundation

struct LibraryModel: Codable, Hashable, Identifiable {
    let imageURL: [String]
    let id: String
    let name: String
    let week: Int
    let clipCount: Int
}

extension LibraryModel {
    static let dummyData: [LibraryModel] = [
        LibraryModel(
            imageURL: ["librarySample1", "librarySample2", "librarySample3"], // from Assets.xcassets
            id: UUID().uuidString,
            name: "Week 12 Recordings",
            week: 12,
            clipCount: 4
        ),
        LibraryModel(
            imageURL: ["librarySample4", "librarySample5"],
            id: UUID().uuidString,
            name: "Week 13 Recordings",
            week: 13,
            clipCount: 2
        ),
        LibraryModel(
            imageURL: ["librarySample6"],
            id: UUID().uuidString,
            name: "Week 14 Recordings",
            week: 14,
            clipCount: 5
        )
    ]
}
