//
//  homeModel.swift
//  tiny
//
//  Created by Tm Revanza Narendra Pradipta on 29/10/25.
//

import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id: String
    var avatar: String
    var name: String
    
    init(name: String, avatar: String) {
        self.name = name
        self.avatar = avatar
        self.id = UUID().uuidString
    }
}

struct PregnancyAge: Codable, Equatable {
    var ageWeeks: Int
    var ageDays: Int
}

struct HomeData: Codable, Equatable {
    let name: String
    let profile: Profile
    let pregnancyAge: PregnancyAge
    
    init(name: String, pregnancyAge: PregnancyAge) {
        self.name = name
        self.profile = Profile(name: name, avatar: "")
        self.pregnancyAge = pregnancyAge
        
    }
}
