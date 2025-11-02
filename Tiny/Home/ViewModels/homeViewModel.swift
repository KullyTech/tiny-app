//
//  homeViewModel.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 29/10/25.
//

import Foundation
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var homeData: HomeData
    
    init(homeData: HomeData) {
        self.homeData = homeData
    }
    
    var displayName: String {
        homeData.name
    }
    var displayAgeWeeks: Int {
        homeData.pregnancyAge.ageWeeks
    }
    var displayAgeDays: Int {
        homeData.pregnancyAge.ageDays
    }
}
