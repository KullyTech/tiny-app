//
//  PlaceholderDot.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 28/11/25.
//

import SwiftUI

struct PlaceholderDot: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 16, height: 16)
                .blur(radius: 4)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
            
            // Inner dot
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PlaceholderDot()
    }
}
