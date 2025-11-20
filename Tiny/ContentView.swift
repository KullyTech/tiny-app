//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    var body: some View {
        Group {
            if hasShownOnboarding {
                OrbLiveListenView()
            } else {
                OnBoardingView(hasShownOnboarding: $hasShownOnboarding)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
