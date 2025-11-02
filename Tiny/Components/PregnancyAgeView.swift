//
//  TrimesterProgress.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 29/10/25.
//

import SwiftUI

struct HeartSearchIcon: View {
    var body: some View {
        HStack(alignment: .center) {
            Image("heartSearch")
        }
    }
}

struct PregnancyAgeDate: View {
    let age: Int
    let timeUnit: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(String(age))
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(Color.bodyDetail)
            Text(timeUnit)
                .font(.title3)
                .fontWeight(.regular)
                .foregroundStyle(Color.body)
        }
        .padding(.horizontal, 8.75)
        .padding(.vertical, 8)
    }
}

struct TrimesterProgressBar: View {
    @State var value: Double
    
    var body: some View {
        VStack {
            Capsule().fill(Color.bar)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule().fill(Color.bodyDetail)
                            .frame(width: proxy.size.width * value)
                    }
                }
                .clipShape(Capsule())
        }
        .frame(width: 92, height: 8)
    }
}

struct EachTrimesterProgress: View {
    var trimesterNumber: Int
    var progressPercentage: Double
    var numFormat: String {
        switch trimesterNumber {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(trimesterNumber)\(numFormat) Trimester")
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(Color.body)
            TrimesterProgressBar(value: progressPercentage)
        }
    }
}

struct PregnancyAgeTimeline: View {
    var body: some View {
        HStack(spacing: 14.5) {
            EachTrimesterProgress(trimesterNumber: 1, progressPercentage: 1)
            EachTrimesterProgress(trimesterNumber: 2, progressPercentage: 0.3)
            EachTrimesterProgress(trimesterNumber: 3, progressPercentage: 0)
        }
    }
}

struct PregnancyAgeText: View {
    var ageWeeks: Int
    var ageDays: Int
    
    var body: some View {
        VStack {
            PregnancyAgeTimeline()
            
            HStack(spacing: 8) {
                PregnancyAgeDate(age: ageWeeks, timeUnit: "Weeks")
                PregnancyAgeDate(age: ageDays, timeUnit: "Days")
            }
        }
        .frame(width: 305)
    }
}

struct PregnancyAgeView: View {
    var ageWeeks: Int
    var ageDays: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Pregnancy Age")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.bodyDetail)
                .frame(maxWidth: .infinity)
            
            HeartSearchIcon()
            
            PregnancyAgeText(ageWeeks: ageWeeks, ageDays: ageDays)
                
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview() {
    PregnancyAgeView(ageWeeks: 6, ageDays: 2)
}
