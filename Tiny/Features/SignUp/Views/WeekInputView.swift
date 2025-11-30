//
//  WeekInputView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 26/11/25.
//

import SwiftUI

struct WeekDistancePreference: Equatable {
    let week: Int
    let distance: CGFloat
}

struct WeekDistanceKey: PreferenceKey {
    static var defaultValue: [WeekDistancePreference] = []
    
    static func reduce(value: inout [WeekDistancePreference], nextValue: () -> [WeekDistancePreference]) {
        value.append(contentsOf: nextValue())
    }
}

enum PregnancyStage {
    case early      // 0–12
    case midEarly   // 12–20
    case midLate    // 20–28
    case late       // 28–HPL

    static func stage(for week: Int) -> PregnancyStage {
        switch week {
        case 0..<12: return .early
        case 12..<20: return .midEarly
        case 20..<28: return .midLate
        default: return .late
        }
    }

    var description: String {
        switch self {
        case .early:
            return "Tiny can let you hear the sounds from your belly."
        case .midEarly:
            return "At this stage, the heartbeat may be harder to capture."
        case .midLate:
            return "At this stage, Tiny is able to capture the heartbeat."
        case .late:
            return "At this stage, the heartbeat is usually clearer."
        }
    }
}

struct WeekInputView: View {
    @State private var selectedWeek: Int = 20
    var onComplete: ((Int) -> Void)?  // Callback when user completes
    
    var body: some View {
        ZStack {
            backgroundView
            VStack(spacing: 148) {
                VStack(spacing: 33) {
                    TitleDescView(selectedWeek: $selectedWeek)
                    CustomWeekPicker(
                        selectedWeek: $selectedWeek,
                        weeks: Array(1...42),
                        height: 254
                    )
                }
                
                Button {
                    // Save selected week to UserDefaults
                    UserDefaults.standard.set(selectedWeek, forKey: "pregnancyWeek")
                    print("💾 Saved pregnancy week: \(selectedWeek)")
                    
                    // Call completion handler
                    onComplete?(selectedWeek)
                } label: {
                    Text("Let's begin")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 152)
                        .padding(.vertical, 13)
                        .background(
                            Color(hex: "393953")
                        )
                        .clipShape(Capsule())
                }
                .glassEffect(.clear.interactive())
            }
        }
    }
}

struct TitleDescView: View {
    @Binding var selectedWeek: Int
        
    var body: some View {
        VStack(spacing: 0) {
            Text("How far along are you?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "E6E6E6"))
            
            Text(PregnancyStage.stage(for: selectedWeek).description)
                .padding()
                .font(.caption)
                .foregroundStyle(Color(hex: "D1CCFF"))
        }
    }
}

private var backgroundView: some View {
    ZStack {
        Color.black.ignoresSafeArea()
        Image("backgroundPurple")
            .resizable()
            .ignoresSafeArea()
    }
}

struct CustomWeekPicker: View {
    @Binding var selectedWeek: Int
    let weeks: [Int]
    let height: CGFloat
    
    private let itemHeight: CGFloat = 40
    
    init(selectedWeek: Binding<Int>, weeks: [Int] = Array(14...20), height: CGFloat = 250) {
        self._selectedWeek = selectedWeek
        self.weeks = weeks
        self.height = height
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(weeks, id: \.self) { week in
                            GeometryReader { itemGeometry in
                                WeekRow(
                                    week: week,
                                    geometry: geometry,
                                    itemGeometry: itemGeometry
                                )
                            }
                            .frame(height: itemHeight)
                            .id(week)
                        }
                    }
                    .padding(.vertical, geometry.size.height / 2 - itemHeight / 2)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(WeekDistanceKey.self) { preferences in
                        if let closest = preferences.min(by: { $0.distance < $1.distance }) {
                            if closest.week != selectedWeek {
                                DispatchQueue.main.async {
                                    self.selectedWeek = closest.week
                                }
                            }
                        }
                }
                .onAppear {
                    proxy.scrollTo(selectedWeek, anchor: .center)
                }
                .simultaneousGesture(
                    DragGesture()
                        .onEnded { _ in
                            snapToNearestWeek(geometry: geometry, proxy: proxy)
                        }
                )
            }
        }
        .frame(height: height)
    }
    
    private func snapToNearestWeek(geometry: GeometryProxy, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            proxy.scrollTo(selectedWeek, anchor: .center)
        }
    }
}

struct WeekRow: View {
    let week: Int
    let geometry: GeometryProxy
    let itemGeometry: GeometryProxy
    
    private var distanceFromCenter: CGFloat {
        let itemCenter = itemGeometry.frame(in: .named("scroll")).midY
        let screenCenter = geometry.size.height / 2
        return abs(itemCenter - screenCenter)
    }
    
    private var scale: CGFloat {
        let maxDistance: CGFloat = 100
        let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
        return 1.0 - (normalizedDistance * 0.4)
    }
    
    private var opacity: CGFloat {
        let maxDistance: CGFloat = 120
        let normalizedDistance = min(distanceFromCenter / maxDistance, 1.0)
        return 1.0 - (normalizedDistance * 0.7)
    }
    
    private var textColor: Color {
        distanceFromCenter < 25 ? Color(hex: "9595E8") : .white
    }
    
    var body: some View {
        Text("\(week) \(week == 1 ? "week" : "weeks")")
            .font(.system(size: 31, weight: .regular))
            .foregroundColor(textColor)
            .scaleEffect(scale)
            .opacity(opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .preference(
                key: WeekDistanceKey.self,
                value: [WeekDistancePreference(week: week, distance: distanceFromCenter)]
            )
    }
}

#Preview {
    WeekInputView()
}
