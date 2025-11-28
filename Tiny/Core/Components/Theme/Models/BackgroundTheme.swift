//
//  BackgroundTheme.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 28/11/25.
//

import Foundation
import SwiftUI

enum BackgroundTheme: String, CaseIterable, Identifiable {
    case purple = "Purple"
    case pink = "Pink"
    case blue = "Blue"
    case black = "Black"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var imageName: String {
        switch self {
        case .purple:
            return "bgPurple"
        case .pink:
            return "bgPink"
        case .blue:
            return "bgBlue"
        case .black:
            return "bgBlack"
        }
    }
}
