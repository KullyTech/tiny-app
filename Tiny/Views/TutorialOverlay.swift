//
//  TutorialOverlay.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 19/11/25.
//

import SwiftUI

struct TutorialOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(spacing: 2) {
                    Text("Replay Your Recording")
                        .font(.body)
                        .fontWeight(.bold)
                    Text("Here's how to control your recording")
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                
                .foregroundColor(.white)
                VStack(alignment: .leading, spacing: -8) {
                    HStack(spacing: 12) {
                        CoachMarkView.small(
                            animationType: .singleTap,
                            showText: false
                        )
                        VStack(alignment: .leading) {
                            Text("Play or Pause")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Tap the screen")
                        }
                        .foregroundColor(.white)
                    }
                    HStack(spacing: 12) {
                        CoachMarkView.small(
                            animationType: .holdAndDrag,
                            showText: false
                        )
                        VStack(alignment: .leading) {
                            Text("Save or Delete")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Hold then drag the sphere")
                        }
                        .foregroundColor(.white)
                    }
                }
                Text("Tap to Continue")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    TutorialOverlay()
}
