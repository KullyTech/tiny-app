//
//  MainTimelineListView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import SwiftUI

struct MainTimelineListView: View {
    let groupedData: [WeekSection]
    @Binding var selectedWeek: WeekSection?
    var animation: Namespace.ID
    
    // Animation support
    @ObservedObject var animationController: TimelineAnimationController
    var isFirstTimeVisit: Bool = false
    
    // Configuration
    private let itemSpacing: CGFloat = 160
    private let wavePeriod: CGFloat = 600
    private let topPadding: CGFloat = 80
    private let bottomPadding: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            let totalItems = groupedData.count
            let contentHeight = max(
                geometry.size.height,
                topPadding + (CGFloat(totalItems) * itemSpacing) + bottomPadding
            )
            
            ZStack {
                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        ZStack(alignment: .top) {
                            let orbPositions = groupedData.enumerated().map { index, _ in
                                topPadding + (CGFloat(index) * itemSpacing)
                            }
                            
                            SegmentedWave(
                                totalHeight: contentHeight,
                                period: wavePeriod,
                                amplitude: geometry.size.width * 0.35,
                                gapPositions: orbPositions,
                                gapSize: 20
                            )
                            .trim(from: 1.0 - animationController.pathProgress, to: 1.0)
                            .stroke(
                                Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: geometry.size.width, height: contentHeight)
                            
                            ForEach(Array(groupedData.enumerated()), id: \.element.id) { index, week in
                                
                                let yPos = topPadding + (CGFloat(index) * itemSpacing)
                                
                                let xPos = TimelineLayout.calculateX(
                                    yCoor: yPos,
                                    width: geometry.size.width,
                                    period: wavePeriod,
                                    amplitude: geometry.size.width * 0.35
                                )
                                
                                VStack(spacing: 8) {
                                    if week.type == .placeholder {
                                        let lastIndex = groupedData.count - 1
                                        
                                        if isFirstTimeVisit {
                                            // First time visit: animate dots and orb transformation
                                            if index == lastIndex && animationController.orbVisible {
                                                // Show orb for the current week (last/bottom item)
                                                ZStack {
                                                    AnimatedOrbView(size: 20)
                                                        .shadow(color: .orange.opacity(0.4), radius: 15)
                                                }
                                                .matchedGeometryEffect(id: "orb_\(week.weekNumber)", in: animation)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                                        selectedWeek = week
                                                    }
                                                }
                                            } else {
                                                // Show dots for future weeks during animation
                                                let reversedIndex = lastIndex - index
                                                if reversedIndex < animationController.dotsVisible.count && animationController.dotsVisible[reversedIndex] {
                                                    PlaceholderDot()
                                                }
                                            }
                                        } else {
                                            // Non-first visit: show orb for current week, dots for future weeks
                                            if index == lastIndex {
                                                // Current week gets an orb
                                                ZStack {
                                                    AnimatedOrbView(size: 20)
                                                        .shadow(color: .orange.opacity(0.4), radius: 15)
                                                }
                                                .matchedGeometryEffect(id: "orb_\(week.weekNumber)", in: animation)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                                        selectedWeek = week
                                                    }
                                                }
                                            } else {
                                                // Future weeks get dots
                                                PlaceholderDot()
                                            }
                                        }
                                    } else {
                                        let shouldShowOrb = !isFirstTimeVisit || (isFirstTimeVisit && animationController.orbVisible)
                                        
                                        if shouldShowOrb {
                                            ZStack {
                                                AnimatedOrbView(size: 20)
                                                    .shadow(color: .orange.opacity(0.4), radius: 15)
                                            }
                                            .matchedGeometryEffect(id: "orb_\(week.weekNumber)", in: animation)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                                    selectedWeek = week
                                                }
                                            }
                                        }
                                    }

                                    let shouldShowLabel: Bool = {
                                        if week.type == .recorded {
                                            return true
                                        } else if week.type == .placeholder {
                                            let lastIndex = groupedData.count - 1
                                            // Show label if it's the current week (last/bottom item)
                                            if isFirstTimeVisit {
                                                return index == lastIndex && animationController.orbVisible
                                            } else {
                                                return index == lastIndex
                                            }
                                        }
                                        return false
                                    }()
                                    
                                    if shouldShowLabel {
                                        Text("Week \(week.weekNumber)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .matchedGeometryEffect(id: "label_\(week.weekNumber)", in: animation)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .position(x: xPos, y: yPos)
                                .id(week.id)
                            }
                        }
                        .frame(width: geometry.size.width, height: contentHeight)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let last = groupedData.last {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.2), location: 0.2),
                        .init(color: .black.opacity(0.5), location: 0.4),
                        .init(color: .black.opacity(0.8), location: 0.6),
                        .init(color: .black.opacity(0.95), location: 0.8),
                        .init(color: .black, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: geometry.size.height * 0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }
        }
    }
}
