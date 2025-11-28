//
//  OrbStyles.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 21/11/25.
//

import SwiftUI

enum OrbStyles: String, CaseIterable, Identifiable {
    case yellow = "Yellow"
    case pink = "Pink"
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var backgorundColors: [Color] {
        switch self {
        case .yellow:
            return [Color("orbYellow"), Color("orbYellow"), .clear]
        case .pink:
            return [Color("orbPink"), Color("orbPink"), .clear]
        case .purple:
            return [Color("orbPurple"), Color("orbPurple"), .clear]
        case .blue:
            return [Color("orbBlue"), Color("orbBlue"), .clear]
        case .green:
            return [Color("orbGreen"), Color("orbGreen"), .clear]
        }
    }
    
    var glowColor: Color {
        switch self {
        case .yellow:
            return Color("orbYellow")
        case .pink:
            return Color("orbPink")
        case .purple:
            return Color("orbPurple")
        case .blue:
            return Color("orbBlue")
        case .green:
            return Color("orbGreen")
        }
    }
    
    var particleColor: Color {
        switch self {
        case .yellow:
            return Color("orbYellow")
        case .pink:
            return Color("orbPink")
        case .purple:
            return Color("orbPurple")
        case .blue:
            return Color("orbBlue")
        case .green:
            return Color("orbGreen")
        }
    }
    
    var bokehColor: Color {
        switch self {
        case .yellow:
            return Color("bokehYellow")
        case .pink:
            return Color("bokehPink")
        case .purple:
            return Color("bokehPurple")
        case .blue:
            return Color("bokehBlue")
        case .green:
            return Color("bokehGreen")
        }
    }
    
}
