//
//  onBoardingView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 27/10/25.
//

import SwiftUI
import UIKit

import SwiftUI
import UIKit

struct OnBoardingView: View {
    @Binding var hasShownOnboarding: Bool

    enum OnboardingPageType: CaseIterable, Identifiable {
        case page1
        case page2

        var id: Self { self }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("background")
                    .resizable()
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(OnboardingPageType.allCases) { pageType in
                            Group {
                                switch pageType {
                                case .page1:
                                    OnboardingPage1()
                                case .page2:
                                    OnboardingPage2(hasShownOnboarding: $hasShownOnboarding)
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
            }
        }
    }
}

private struct OnboardingPage1: View {
    @State private var scanOffset: CGFloat = -40   // Start left
    @State private var rotation: Double = -5       // Small tilt

    var titleText: AttributedString {
        var string = AttributedString("What can you do with tiny?")
        if let range = string.range(of: "tiny") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        ZStack {
            Image("bgOnboarding1")
                .scaledToFill()
                .offset(y: 130)

            VStack(spacing: 16) {

                ZStack {
                    VStack {
                        Image("handHoldingPhone")
                            .offset(x: scanOffset)
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 2.4)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    scanOffset = 40       // move right
                                    rotation = 5          // tilt to the right
                                }
                            }

                        Image("stomach")
                    }
                }

                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("You can listen to your baby's heartbeat live and record it to listen again later")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }
}

private struct OnboardingPage2: View {
    @Binding var hasShownOnboarding: Bool  // Add this line
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
            Image("bgOnboarding2")
                .scaledToFill()
                .offset(y: -340)

            VStack {
                HStack {
                    Image(systemName: "airpod.gen3.right")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(-10))

                    Image(systemName: "airpod.gen3.left")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(10))
                        .offset(y: 10)
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white,
                            .white.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                Text("Tiny will need access to your microphone so you can hear every tiny beat clearly")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Button(action: {
                    manager.requestMicrophonePermission { granted in
                        if granted {
                            print("Permission granted")
                            hasShownOnboarding = true  // Dismiss onboarding when permission is granted
                        } else {
                            showDeniedAlert = true
                        }
                    }
                }, label: {
                    Text("Let's go")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 40)
                        .foregroundColor(.white)
                        .glassEffect()
                })
                .padding(.top, 20)
                .alert("Microphone Access Denied", isPresented: $showDeniedAlert) {
                    Button("OK", role: .cancel) { }
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } message: {
                    Text("Please enable microphone access in Settings to use this feature.")
                }
            }
        }
    }
}

#Preview {
    OnBoardingView(hasShownOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview {
    OnBoardingView(hasShownOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
