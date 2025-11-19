//
//  TutorialOverlay.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 19/11/25.
//

import SwiftUI

struct TutorialOverlay: View {
    @Binding var showTutorial: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Hear Baby's Heartbeat")
                        .font(.body)
                        .fontWeight(.bold)
                    Text("Here's how to control your session")
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                
                .foregroundColor(.white)
                VStack(alignment: .leading, spacing: -28) {
                    HStack(spacing: 0) {
                        CoachMarkView.small(
                            animationType: .doubleTap,
                            showText: false
                        )
                        VStack(alignment: .leading) {
                            Text("Start session")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Tap twice")
                        }
                        .foregroundColor(.white)
                    }
                    HStack(spacing: 0) {
                        CoachMarkView.small(
                            animationType: .hold,
                            showText: false
                        )
                        VStack(alignment: .leading) {
                            Text("Finish Session")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Press and hold the sphere")
                        }
                        .foregroundColor(.white)
                    }
                }
                Text("Tap to Begin")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .onTapGesture {
            showTutorial = false
            UserDefaults.standard.set(true, forKey: "hasShownTutorial")
        }
    }
}

#Preview {
    TutorialOverlay(showTutorial: .constant(true))
}
