//
//  CountdownTextView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 18/11/25.
//

import SwiftUI

struct CountdownTextView: View {
    let countdown: Int
    let isVisible: Bool
    
    var body: some View {
        VStack {
            if isVisible {
                VStack(spacing: 8) {
                    Text("Hold to stop")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("\(countdown)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .scaleEffect(countdown > 0 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: countdown)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CountdownTextView(countdown: 3, isVisible: true)
    }
}
