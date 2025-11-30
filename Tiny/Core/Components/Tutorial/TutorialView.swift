//
//  TutorialView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 01/12/25.
//

import SwiftUI

// ---------------------------------------------------------
// MARK: - Highlighted Word Component
// ---------------------------------------------------------
struct HighlightedWordText: View {
    let fullText: String
    let highlight: String
    let highlightColor: Color

    var body: some View {
        Text(makeAttributed())
    }

    private func makeAttributed() -> AttributedString {
        var attributed = AttributedString(fullText)

        if let range = attributed.range(of: highlight) {
            attributed[range].foregroundColor = highlightColor
        }
        return attributed
    }
}

// ---------------------------------------------------------
// MARK: MAIN TUTORIAL VIEW
// ---------------------------------------------------------
struct TutorialView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                TutorialPage1()
                TutorialPage2()
                TutorialPage3()
                TutorialPage4()
            }
            .padding(.bottom, 40)
        }
        .background(
            GeometryReader { geo in
                Image("bgPurpleOnboarding")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width,
                           height: geo.size.height)
                    .clipped()        // prevents blank leftover area
            }
            .ignoresSafeArea()
        )
    }
}

// ---------------------------------------------------------
// MARK: TUTORIAL PAGE 1
// ---------------------------------------------------------
struct TutorialPage1: View {
    @State private var phoneOffset: CGFloat = -40
    @State private var phoneRotation: Double = -5

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Tiny")
            .font(.title)
            .fontWeight(.bold)
            .padding(.horizontal, 30)

            Text("your gentle guide")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

            // Title
            HighlightedWordText(
                fullText: "What can you do with Tiny",
                highlight: "Tiny",
                highlightColor: Color("mainYellow")
            )
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 30)

            Text("Connect your AirPods and let Tiny access your microphone to hear every little beat.")
                .font(.body)
                .padding(.horizontal, 30)

            HStack {
                Spacer()
                ZStack {
                    VStack {
                        Image("handHoldingPhone")
                            .offset(x: phoneOffset)
                            .rotationEffect(.degrees(phoneRotation))
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                                    phoneOffset = 40
                                    phoneRotation = 5
                                }
                            }

                        Image("stomach")
                    }
                }
                Spacer()
            }
            .padding(.top, 20)
        }
        .padding(.vertical, 80)
    }
}

// ---------------------------------------------------------
// MARK: TUTORIAL PAGE 2
// ---------------------------------------------------------
struct TutorialPage2: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HighlightedWordText(
                fullText: "Feel the best experience",
                highlight: "best",
                highlightColor: Color("mainYellow")
            )
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 30)

            Text("Tiny will need access to your microphone so you can hear every tiny beat clearly.")
                .font(.body)
                .padding(.horizontal, 30)

            HStack {
                Spacer()

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
                        gradient: Gradient(colors: [.white, .white.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()
            }
            .padding(.top, 20)
        }
        .padding(.vertical, 80)
    }
}

// ---------------------------------------------------------
// MARK: TUTORIAL PAGE 3
// ---------------------------------------------------------
struct TutorialPage3: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HighlightedWordText(
                fullText: "Grow through every moment",
                highlight: "moment",
                highlightColor: Color("mainYellow")
            )
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 30)

            Text("Share how you feel today and let love keep you both close.")
                .font(.body)
                .padding(.horizontal, 30)

            HStack {
                Spacer()

                Image("onboardingShareMood")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .padding(.top, 20)

                Spacer()
            }
        }
        .padding(.vertical, 80)
    }
}

// ---------------------------------------------------------
// MARK: TUTORIAL PAGE 4
// ---------------------------------------------------------
struct TutorialPage4: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {

            // SECTION 1 - full white title
            HighlightedWordText(
                fullText: "To hear every little beat clearly:",
                highlight: "",
                highlightColor: Color("mainYellow")
            )
            .font(.title3)
            .fontWeight(.bold)

            section(
                title: "",
                bullets: [
                    "Allow Tiny to access your microphone",
                    "Connect your AirPods / TWS",
                    "Remove your phone case",
                    "Make sure nothing blocks your iPhone’s mic",
                    "Place the phone directly on skin",
                    "Find a quiet room",
                    "Tiny works offline — no internet needed"
                ]
            )

            // SECTION 2 - only "companion" yellow
            VStack(alignment: .leading, spacing: 12) {

                HighlightedWordText(
                    fullText: "Sweet companion for bonding",
                    highlight: "companion",
                    highlightColor: Color("mainYellow")
                )
                .font(.title3)
                .fontWeight(.bold)

                Text("Every pregnancy is beautifully different, so results may vary. Be gentle with yourself if it doesn’t work right away.")
                    .font(.body)

                section(
                    title: "",
                    bullets: [
                        "Baby’s position may not align with the mic",
                        "Skin thickness varies with every pregnancy",
                        "Sometimes it’s the device or technology",
                        "Early weeks: heartbeat may still be too faint"
                    ]
                )
            }

            // SECTION 3 - full white title
            section(
                title: "To hear every little beat clearly:",
                bullets: [
                    "Baby’s position is unpredictable",
                    "Skin thickness varies",
                    "Sometimes it’s simply the device & technology",
                    "Early weeks: heartbeat may still be too faint"
                ]
            )

            // SECTION 4 - only "Navigate" yellow
            VStack(alignment: .leading, spacing: 16) {

                HighlightedWordText(
                    fullText: "Navigate between features",
                    highlight: "Navigate",
                    highlightColor: Color("mainYellow")
                )
                .font(.title3)
                .fontWeight(.bold)

                Text("Control your screen with a simple gesture:")
                    .font(.body)

                section(
                    title: "LIVE LISTEN",
                    bullets: [
                        "Start session → Double-tap the sphere",
                        "Stop session → Press & hold the sphere"
                    ]
                )

                section(
                    title: "PLAYBACK",
                    bullets: [
                        "Play recording → Tap the sphere",
                        "Pause / stop → Tap again"
                    ]
                )

                section(
                    title: "SAVE RECORDING",
                    bullets: [
                        "Hold + drag down → Delete recording",
                        "Hold + swipe up → Save recording"
                    ]
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 40)
    }

    // -----------------------------------------------------
    // MARK: UNIVERSAL BULLET SECTION
    // -----------------------------------------------------
    func section(title: String, bullets: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            if !title.isEmpty {
                Text(title)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
    }
}

#Preview {
    TutorialView()
        .preferredColorScheme(.dark)
}
