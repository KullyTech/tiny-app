//
//  OrbWeekView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 19/11/25.
//

import SwiftUI

struct OrbWeekView: View {
    private var week: Int = 12
    var body: some View {
        VStack(spacing: 13) {
            AnimatedOrbView(size: 48)
            Text("Week \(week)")
                .font(Font.caption)
                .fontWeight(Font.Weight.bold)
                .foregroundStyle(.white)
        }
        .onTapGesture {
        }
    }
}

#Preview {
    ZStack {
        Color.black
        OrbWeekView()
    }
    .ignoresSafeArea()
}
