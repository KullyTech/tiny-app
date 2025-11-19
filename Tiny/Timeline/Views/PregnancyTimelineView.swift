//
//  TimelineView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 18/11/25.
//

import SwiftUI
import SpriteKit

struct PregnancyTimelineView: View {
    @State private var isExpanded = false
    @State private var showDates = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack {
                if isExpanded {
                    Text("Week 20")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.opacity)
                        .padding(.top, 80)
                }
                
                Spacer()
            }
            
            // Timeline path with nodes
            TimelinePathView(isExpanded: isExpanded, showDates: showDates)
            
            // Main sphere
            VStack {
                Spacer()
                
                if !isExpanded {
                    Text("Week 20")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .offset(y: -20)
                        .transition(.opacity)
                }
                
                Spacer()
                    .frame(height: isExpanded ? 200 : 400)
            }
            
            // Animated Orb with size parameter
            AnimatedOrbView(size: isExpanded ? 116 : 48)
                .offset(y: isExpanded ? -280 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
                .onTapGesture {
                    if !isExpanded {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                            showDates = true
                        }
                    }
                }
                .zIndex(1)
            
            // Bottom book button / Back button (morphing animation)
            GeometryReader { geometry in
                Button(action: {
                    if !isExpanded {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = true
                        }
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                            showDates = true
                        }
                    } else {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = false
                            showDates = false
                        }
                    }
                }) {
                    ZStack {
                        // Book icon
                        Image(systemName: "book.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .opacity(isExpanded ? 0 : 1)
                            .scaleEffect(isExpanded ? 0.5 : 1)
                        
                        // Chevron icon
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(isExpanded ? 1 : 0)
                            .scaleEffect(isExpanded ? 1 : 0.5)
                    }
                    .frame(width: isExpanded ? 50 : 77, height: isExpanded ? 50 : 77)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isExpanded ? 0 : 0.3), lineWidth: 1)
                    )
                }
                .position(
                    x: isExpanded ? 45 : geometry.size.width / 2,
                    y: isExpanded ? 85 : geometry.size.height - 100
                )
            }
        }
    }
}

struct TimelinePathView: View {
    let isExpanded: Bool
    let showDates: Bool
    
    let dates = [
        "10 November 2025",
        "09 November 2025",
        "08 November 2025",
        "07 November 2025"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Curved path
                CurvedPath()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Nodes along the path
                if !isExpanded {
                    // Initial state - small nodes
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .shadow(color: .white, radius: 8, x: 0, y: 0)
                            .position(getNodePosition(index: index, in: geometry.size))
                    }
                }
                
                if showDates {
                    // Expanded state - date entries
                    ForEach(0..<dates.count, id: \.self) { index in
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .shadow(color: .white, radius: 10, x: 0, y: 0)
                            
                            Text(dates[index])
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .position(getDatePosition(index: index, in: geometry.size))
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    func getNodePosition(index: Int, in size: CGSize) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.3, 0.25),  // Top node
            (0.2, 0.45),  // Middle-left node
            (0.5, 0.85)   // Bottom node
        ]
        return CGPoint(x: size.width * positions[index].0, y: size.height * positions[index].1)
    }
    
    func getDatePosition(index: Int, in size: CGSize) -> CGPoint {
        let yPositions: [CGFloat] = [0.35, 0.50, 0.65, 0.80]
        let xOffset: CGFloat = 0.35
        return CGPoint(x: size.width * xOffset, y: size.height * yPositions[index])
    }
}

struct CurvedPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.15))
        
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.5),
            control1: CGPoint(x: width * 0.1, y: height * 0.25),
            control2: CGPoint(x: width * 0.05, y: height * 0.38)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.85),
            control1: CGPoint(x: width * 0.25, y: height * 0.62),
            control2: CGPoint(x: width * 0.35, y: height * 0.75)
        )
        
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 1.1),
            control1: CGPoint(x: width * 0.65, y: height * 0.95),
            control2: CGPoint(x: width * 0.5, y: height * 1.05)
        )
        
        return path
    }
}

#Preview {
    PregnancyTimelineView()
}
