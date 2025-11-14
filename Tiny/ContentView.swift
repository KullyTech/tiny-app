//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var heartbeatSoundManager = HeartbeatSoundManager()
    @State private var isListening = false
    @State private var animateOrb = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)

                // Orb View
                VStack {
                    AnimatedOrbView()
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateOrb ? 1.5 : 1)
                        .offset(y: animateOrb ? geometry.size.height / 2 - 150 : 0)
                        .onTapGesture(count: 2) {
                            withAnimation(.interpolatingSpring(mass: 2, stiffness: 100, damping: 20)) {
                                animateOrb.toggle()
                                isListening.toggle()
                                if isListening {
                                    heartbeatSoundManager.start()
                                } else {
                                    heartbeatSoundManager.stop()
                                }
                            }
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    ContentView()
}
