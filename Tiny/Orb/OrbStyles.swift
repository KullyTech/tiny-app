//
//  OrbStyles.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 21/11/25.
//

import SwiftUI

enum OrbStyles: String, CaseIterable, Identifiable {
    case ocean = "Ocean"
    case defaultStyle = "Default"
    case forest = "Forest"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var backgorundColors: [Color] {
        switch self {
        case .ocean:
            return [.blue, .cyan, .clear]
        case .forest:
            return [.green, .mint, .clear]
        case .defaultStyle:
            return [.orange, .orbOrange, .clear]
        }
    }
    
    var glowColor: Color {
        switch self {
        case .ocean:
            return .cyan.opacity(1)
        case .forest:
            return .green.opacity(1)
        case .defaultStyle:
            return .orbOrange.opacity(1)
        }
    }
    
    var particleColor: Color {
        switch self {
        case .ocean:
            return .cyan
        case .forest:
            return .green
        case .defaultStyle:
            return .white
        }
    }
    
}
