//
//  TimelineModels.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import Foundation

import SwiftUI

// Data Model
struct WeekSection: Identifiable, Equatable {
    let id = UUID()
    let weekNumber: Int
    let recordings: [Recording]
}

// Shared Helper
struct TimelineLayout {
    static func calculateX(yCoor: CGFloat, width: CGFloat, period: CGFloat, amplitude: CGFloat, phase: CGFloat = 0) -> CGFloat {
        let centerX = width / 2
        let angle = ((yCoor / period) * .pi * 2) + phase
        return centerX + sin(angle) * amplitude
    }
}

// Shared Shape
struct ContinuousWave: Shape {
    var totalHeight: CGFloat
    var period: CGFloat
    var amplitude: CGFloat
    var phase: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        
        let startAngle = phase
        let startX = centerX + sin(startAngle) * amplitude
        let startPoint = CGPoint(x: startX, y: 0)
        
        path.move(to: startPoint)
        
        // Draw sine wave with a step of 5 pixels
        for yCoord in stride(from: 0, through: totalHeight, by: 5) {
            let angle = ((yCoord / period) * .pi * 2) + phase
            let xCoord = centerX + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: xCoord, y: yCoord))
        }
        return path
    }
}
