//
//  OnBoardingView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 27/10/25.
//

import SwiftUI
import UIKit

struct OnBoardingView: View {
    @Binding var hasShownOnboarding: Bool

    enum OnboardingPageType: CaseIterable, Identifiable {
        case page0
        case page1
        case page2
        case page3
        case page4

        var id: Self { self }
    }

    private let pages = OnboardingPageType.allCases

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ZStack(alignment: .top) {

                    // Purple blur background image
                    Image("bgPurpleOnboarding")
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height * CGFloat(pages.count),
                            alignment: .top           // ← makes sure it pins to the top
                        )
                        .clipped()
                        .ignoresSafeArea()

                    // Line background image
                    Image("lineOnboarding")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height * CGFloat(pages.count)
                        )
                        .clipped()
                        .offset(y: 120)

                    // Yellow heart scrolling down following lineOnboarding image
                    Image("yellowHeart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)

                    VStack(spacing: 0) {
                        ForEach(pages) { page in
                            pageView(for: page)
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height
                                )
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    func pageView(for page: OnboardingPageType) -> some View {
        switch page {
        case .page0:
            OnboardingPage0()
        case .page1:
            OnboardingPage1()
        case .page2:
            OnboardingPage2()
        case .page3:
            OnboardingPage3()
        case .page4:
            OnboardingPage4(hasShownOnboarding: $hasShownOnboarding)
        }
    }
}

private struct OnboardingPage0: View {
    var titleText: AttributedString {
        var string = AttributedString("Hello lovely parents!")
        if let range = string.range(of: "lovely") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                VStack {
                    Text(titleText)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()

                    Text("You can listen to your baby's heartbeat live and record it to listen again later.")
                        .font(.body)
                        .fontWeight(.regular)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2 - 180)  // 🔥 Shift up
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Connect your AirPods and let Tiny access your microphone to hear every little beat.")
                    .font(.body)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }
}

private struct OnboardingPage2: View {
    var titleText: AttributedString {
        var string = AttributedString("Feel the best experience")
        if let range = string.range(of: "best") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        ZStack {
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Text("Tiny will need access to your microphone so you can hear every tiny beat clearly.")
                    .font(.body)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct OnboardingPage3: View {
    var titleText: AttributedString {
        var string = AttributedString("Grow through every moment")
        if let range = string.range(of: "moment") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        ZStack(alignment: .top){
            VStack {
                Text(titleText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(5)

                Text("Share how you feel today and let love keep you both close.")
                    .font(.body)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct OnboardingPage4: View {
    @StateObject private var manager = HeartbeatSoundManager()
    @Binding var hasShownOnboarding: Bool  // Add this line
    @State private var showDeniedAlert = false

    var titleText: AttributedString {
        var string = AttributedString("Hello lovely parents!")
        if let range = string.range(of: "lovely") {
            string[range].foregroundColor = Color("mainYellow")
        }
        return string
    }

    var body: some View {
        VStack {
            Spacer()

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
        .padding(50)
    }
}

#Preview {
    OnBoardingView(hasShownOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview("Page 0 Preview") {
    OnboardingPage0()
        .preferredColorScheme(.dark)
}

#Preview("Page 1 Preview") {
    OnboardingPage1()
        .preferredColorScheme(.dark)
}

#Preview("Page 2 Preview") {
    OnboardingPage2()
        .preferredColorScheme(.dark)
}

#Preview("Page 3 Preview") {
    OnboardingPage3()
        .preferredColorScheme(.dark)
}

#Preview("Page 4 Preview") {
    OnboardingPage4(hasShownOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
