//
//  TutorialOverlay.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 19/11/25.
//

import SwiftUI

enum TutorialContext {
    case initial, listening
}

struct TutorialOverlay: View {
    @Binding var activeTutorial: TutorialContext?
    let context: TutorialContext

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            switch context {
            case .initial:
                initialTutorialView
            case .listening:
                listeningTutorialView
            }
        }
        .onTapGesture {
            switch context {
            case .initial:
                UserDefaults.standard.set(true, forKey: "hasShownInitialTutorial")
            case .listening:
                UserDefaults.standard.set(true, forKey: "hasShownListeningTutorial")
            }
            activeTutorial = nil
        }
    }

    private var initialTutorialView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 2) {
                Text("Hear Baby's Heartbeat")
                    .font(.body)
                    .fontWeight(.bold)
                Text("Here's how to control your session")
                    .font(.subheadline)
            }
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
                        Text("Finish session")
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
    
    private var listeningTutorialView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 2) {
                Text("Replay Your Recording")
                    .font(.body)
                    .fontWeight(.bold)
                Text("Here's how to control your session")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: -28) {
                HStack(spacing: 0) {
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
                HStack(spacing: 0) {
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

#Preview {
    TutorialOverlay(activeTutorial: .constant(.initial), context: .listening)
}
