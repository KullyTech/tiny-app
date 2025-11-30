//
//  TimelineModels.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import Foundation

import SwiftUI

// MARK: - Data Model
enum WeekType {
    case recorded  // Week with actual recordings
    case placeholder  // Future week placeholder
}

enum TimelineItem: Identifiable, Equatable {
    case recording(Recording)
    case moment(Moment)
    
    var id: UUID {
        switch self {
        case .recording(let recording): return recording.id
        case .moment(let moment): return moment.id
        }
    }
    
    var createdAt: Date {
        switch self {
        case .recording(let recording): return recording.createdAt
        case .moment(let moment): return moment.createdAt
        }
    }
}

struct WeekSection: Identifiable, Equatable {
    let id = UUID()
    let weekNumber: Int
    let recordings: [Recording]
    let type: WeekType
    
    init(weekNumber: Int, recordings: [Recording], type: WeekType = .recorded) {
        self.weekNumber = weekNumber
        self.recordings = recordings
        self.type = type
    }
}

// MARK: - Shared Helper
struct TimelineLayout {
    static func calculateX(yCoor: CGFloat, width: CGFloat, period: CGFloat, amplitude: CGFloat) -> CGFloat {
        let centerX = width / 2
        let angle = (yCoor / period) * .pi * 2
        return centerX + sin(angle) * amplitude
    }
}

// MARK: - Shared Shape
struct ContinuousWave: Shape {
    var totalHeight: CGFloat
    var period: CGFloat
    var amplitude: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        let startPoint = CGPoint(x: centerX, y: 0)
        path.move(to: startPoint)
        
        // Draw sine wave with a step of 5 pixels
        for yCoord in stride(from: 0, through: totalHeight, by: 5) {
            let angle = (yCoord / period) * .pi * 2
            let xCoord = centerX + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: xCoord, y: yCoord))
        }
        return path
    }
}

// MARK: - Wave with Gaps for Orbs
struct SegmentedWave: Shape {
    var totalHeight: CGFloat
    var period: CGFloat
    var amplitude: CGFloat
    var gapPositions: [CGFloat] // Y positions where gaps should be
    var gapSize: CGFloat = 30 // Size of gap around each position
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        var isDrawing = false
        
        // Draw sine wave with gaps at orb positions
        for yCoord in stride(from: 0, through: totalHeight, by: 5) {
            // Check if we're in a gap
            let inGap = gapPositions.contains { abs(yCoord - $0) < gapSize }
            
            let angle = (yCoord / period) * .pi * 2
            let xCoord = centerX + sin(angle) * amplitude
            let point = CGPoint(x: xCoord, y: yCoord)
            
            if inGap {
                // We're in a gap, stop drawing
                isDrawing = false
            } else {
                // We're not in a gap, continue or start drawing
                if !isDrawing {
                    path.move(to: point)
                    isDrawing = true
                } else {
                    path.addLine(to: point)
                }
            }
        }
        return path
    }
}
