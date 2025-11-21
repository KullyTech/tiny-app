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
    
    // Configuration
    private let itemSpacing: CGFloat = 160
    private let wavePeriod: CGFloat = 600
    private let topPadding: CGFloat = 150
    private let bottomPadding: CGFloat = 200
    
    var body: some View {
        GeometryReader { geometry in
            let totalItems = groupedData.count
            let contentHeight = max(
                geometry.size.height,
                topPadding + (CGFloat(totalItems) * itemSpacing) + bottomPadding
            )
            
            ScrollView(showsIndicators: false) {
                // Reader to scroll to bottom if needed (optional)
                ScrollViewReader { proxy in
                    ZStack(alignment: .top) {
                        // 1. Wavy Line
                        ContinuousWave(
                            totalHeight: contentHeight,
                            period: wavePeriod,
                            amplitude: geometry.size.width * 0.35
                        )
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .white.opacity(0.2), location: 0.1),
                                    .init(color: .white.opacity(0.3), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: geometry.size.width, height: contentHeight)
                        
                        // 2. Week Orbs
                        // Iterate directly: Index 0 (Earliest Week) -> Top
                        ForEach(Array(groupedData.enumerated()), id: \.element.id) { index, week in
                            
                            // Simple linear progression: 0 is Top, Max is Bottom
                            let yPos = topPadding + (CGFloat(index) * itemSpacing)
                            
                            let xPos = TimelineLayout.calculateX(
                                yCoor: yPos,
                                width: geometry.size.width,
                                period: wavePeriod,
                                amplitude: geometry.size.width * 0.35
                            )
                            
                            VStack(spacing: 8) {
                                // The Orb
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
                                
                                // Label
                                Text("Week \(week.weekNumber)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .matchedGeometryEffect(id: "label_\(week.weekNumber)", in: animation)
                            }
                            .frame(width: 120, height: 120)
                            .position(x: xPos, y: yPos)
                            .id(week.id) // Useful for auto-scrolling
                        }
                    }
                    .frame(width: geometry.size.width, height: contentHeight)
                    .onAppear {
                        // Optional: Auto-scroll to the latest week (bottom)
                        if let last = groupedData.last {
                            proxy.scrollTo(last.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
