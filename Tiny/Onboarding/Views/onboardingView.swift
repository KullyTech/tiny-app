//
//  onBoardingView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 27/10/25.
//

import SwiftUI

struct OnBoardingView: View {
    @Binding var hasShownOnboarding: Bool
    
    var body: some View {
        ZStack {
            TabView {
                OnboardingPage1()
                OnboardingPage2(hasShownOnboarding: $hasShownOnboarding)
            }
            .tabViewStyle(.page)
        }
    }
}

private struct OnboardingPage1: View {

    var titleText: AttributedString {
        var string = AttributedString("What can you do with Tiny?")
        if let range = string.range(of: "Tiny") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()

            VStack {
                Image("handHoldingPhone")
                Image("stomach")

                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                Text("You can listen to your baby’s heartbeat live and record it to listen again later")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct OnboardingPage2: View {
    @Binding var hasShownOnboarding: Bool
    @StateObject private var manager = HeartbeatSoundManager()
    @State private var showDeniedAlert = false

    var titleText: AttributedString {
        var string = AttributedString("Feel the best experience")
        if let range = string.range(of: "best") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Image(systemName: "airpod.gen3.right")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(-10))   // rotate LEFT

                    Image(systemName: "airpod.gen3.left")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(10))    // rotate RIGHT
                        .offset(y: 10)
                }

                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                Text("Tiny will need access to your microphone so you can hear every tiny beat clearly")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Button(action: {
                    // Action to ask microphone permission
                    manager.requestMicrophonePermission { granted in
                        if granted {
                            print("Permission granted")
                        } else {
                            showDeniedAlert = true
                        }
                        hasShownOnboarding = true
                    }

                }, label: {
                    Text("Allow Access")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 40)
                        .foregroundColor(.white)
                        .glassEffect()
                })
                .padding()
            }
        }
    }
}

#Preview {
    OnBoardingView(hasShownOnboarding: .constant(false))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}

#Preview("Page 1") {
    OnboardingPage1()
        .ignoresSafeArea()
}

#Preview("Page 2") {
    OnboardingPage2(hasShownOnboarding: .constant(false))
        .ignoresSafeArea()
}
