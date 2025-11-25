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
                        .frame(width: 40)
                        .offset(y: 370)

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
        ZStack(alignment: .top) {
            VStack {
                Image("onboardingShareMood")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
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

struct LinePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.46853*width, y: 0.00006*height))
        path.addCurve(to: CGPoint(x: 0.47069*width, y: 0.00003*height), control1: CGPoint(x: 0.46904*width, y: -0.00001*height), control2: CGPoint(x: 0.47001*width, y: -0.00002*height))
        path.addCurve(to: CGPoint(x: 0.50231*width, y: 0.00418*height), control1: CGPoint(x: 0.48713*width, y: 0.00131*height), control2: CGPoint(x: 0.49731*width, y: 0.0027*height))
        path.addCurve(to: CGPoint(x: 0.50295*width, y: 0.00887*height), control1: CGPoint(x: 0.50731*width, y: 0.00566*height), control2: CGPoint(x: 0.50707*width, y: 0.00722*height))
        path.addCurve(to: CGPoint(x: 0.44179*width, y: 0.01969*height), control1: CGPoint(x: 0.49474*width, y: 0.01214*height), control2: CGPoint(x: 0.47099*width, y: 0.01576*height))
        path.addCurve(to: CGPoint(x: 0.34699*width, y: 0.03253*height), control1: CGPoint(x: 0.41252*width, y: 0.02363*height), control2: CGPoint(x: 0.37773*width, y: 0.02791*height))
        path.addCurve(to: CGPoint(x: 0.27704*width, y: 0.0474*height), control1: CGPoint(x: 0.31628*width, y: 0.03715*height), control2: CGPoint(x: 0.28975*width, y: 0.04211*height))
        path.addCurve(to: CGPoint(x: 0.30016*width, y: 0.06937*height), control1: CGPoint(x: 0.25934*width, y: 0.05476*height), control2: CGPoint(x: 0.27196*width, y: 0.06212*height))
        path.addCurve(to: CGPoint(x: 0.41661*width, y: 0.09074*height), control1: CGPoint(x: 0.32837*width, y: 0.07663*height), control2: CGPoint(x: 0.37214*width, y: 0.08378*height))
        path.addCurve(to: CGPoint(x: 0.53703*width, y: 0.11092*height), control1: CGPoint(x: 0.46104*width, y: 0.09769*height), control2: CGPoint(x: 0.50621*width, y: 0.10445*height))
        path.addCurve(to: CGPoint(x: 0.57155*width, y: 0.12939*height), control1: CGPoint(x: 0.56786*width, y: 0.11738*height), control2: CGPoint(x: 0.5845*width, y: 0.12357*height))
        path.addCurve(to: CGPoint(x: 0.50718*width, y: 0.14064*height), control1: CGPoint(x: 0.56169*width, y: 0.13381*height), control2: CGPoint(x: 0.5381*width, y: 0.13731*height))
        path.addCurve(to: CGPoint(x: 0.39854*width, y: 0.15091*height), control1: CGPoint(x: 0.47632*width, y: 0.14397*height), control2: CGPoint(x: 0.43791*width, y: 0.14715*height))
        path.addCurve(to: CGPoint(x: 0.19655*width, y: 0.18689*height), control1: CGPoint(x: 0.31969*width, y: 0.15845*height), control2: CGPoint(x: 0.23594*width, y: 0.16841*height))
        path.addCurve(to: CGPoint(x: 0.27432*width, y: 0.21229*height), control1: CGPoint(x: 0.17535*width, y: 0.19684*height), control2: CGPoint(x: 0.21005*width, y: 0.2051*height))
        path.addCurve(to: CGPoint(x: 0.52911*width, y: 0.23126*height), control1: CGPoint(x: 0.33863*width, y: 0.21949*height), control2: CGPoint(x: 0.43245*width, y: 0.22561*height))
        path.addCurve(to: CGPoint(x: 0.8004*width, y: 0.2474*height), control1: CGPoint(x: 0.62568*width, y: 0.2369*height), control2: CGPoint(x: 0.72516*width, y: 0.24209*height))
        path.addCurve(to: CGPoint(x: 0.892*width, y: 0.25558*height), control1: CGPoint(x: 0.83804*width, y: 0.25006*height), control2: CGPoint(x: 0.86972*width, y: 0.25276*height))
        path.addCurve(to: CGPoint(x: 0.92725*width, y: 0.2645*height), control1: CGPoint(x: 0.91429*width, y: 0.2584*height), control2: CGPoint(x: 0.92725*width, y: 0.26135*height))
        path.addLine(to: CGPoint(x: 0.92725*width, y: 0.26451*height))
        path.addLine(to: CGPoint(x: 0.92723*width, y: 0.26452*height))
        path.addCurve(to: CGPoint(x: 0.87378*width, y: 0.27424*height), control1: CGPoint(x: 0.92175*width, y: 0.26799*height), control2: CGPoint(x: 0.90268*width, y: 0.2712*height))
        path.addCurve(to: CGPoint(x: 0.76081*width, y: 0.28288*height), control1: CGPoint(x: 0.84487*width, y: 0.27727*height), control2: CGPoint(x: 0.80603*width, y: 0.28012*height))
        path.addCurve(to: CGPoint(x: 0.44007*width, y: 0.29887*height), control1: CGPoint(x: 0.67039*width, y: 0.2884*height), control2: CGPoint(x: 0.55413*width, y: 0.29354*height))
        path.addCurve(to: CGPoint(x: 0.13195*width, y: 0.31605*height), control1: CGPoint(x: 0.32594*width, y: 0.30421*height), control2: CGPoint(x: 0.214*width, y: 0.30974*height))
        path.addCurve(to: CGPoint(x: 0.00348*width, y: 0.33778*height), control1: CGPoint(x: 0.04987*width, y: 0.32236*height), control2: CGPoint(x: -0.00189*width, y: 0.32941*height))
        path.addCurve(to: CGPoint(x: 0.18482*width, y: 0.36315*height), control1: CGPoint(x: 0.01182*width, y: 0.3508*height), control2: CGPoint(x: 0.08341*width, y: 0.35885*height))
        path.addCurve(to: CGPoint(x: 0.54332*width, y: 0.36601*height), control1: CGPoint(x: 0.28585*width, y: 0.36744*height), control2: CGPoint(x: 0.41645*width, y: 0.368*height))
        path.addCurve(to: CGPoint(x: 0.68115*width, y: 0.32467*height), control1: CGPoint(x: 0.49289*width, y: 0.34814*height), control2: CGPoint(x: 0.57308*width, y: 0.3324*height))
        path.addCurve(to: CGPoint(x: 0.85226*width, y: 0.31983*height), control1: CGPoint(x: 0.73537*width, y: 0.32079*height), control2: CGPoint(x: 0.79673*width, y: 0.31892*height))
        path.addCurve(to: CGPoint(x: 0.98787*width, y: 0.3316*height), control1: CGPoint(x: 0.90787*width, y: 0.32074*height), control2: CGPoint(x: 0.9574*width, y: 0.32442*height))
        path.addCurve(to: CGPoint(x: 0.98315*width, y: 0.34301*height), control1: CGPoint(x: 1.00435*width, y: 0.33549*height), control2: CGPoint(x: 1.0012*width, y: 0.33935*height))
        path.addCurve(to: CGPoint(x: 0.88929*width, y: 0.35322*height), control1: CGPoint(x: 0.96512*width, y: 0.34667*height), control2: CGPoint(x: 0.93226*width, y: 0.35013*height))
        path.addCurve(to: CGPoint(x: 0.5473*width, y: 0.36627*height), control1: CGPoint(x: 0.80372*width, y: 0.35939*height), control2: CGPoint(x: 0.67768*width, y: 0.36417*height))
        path.addCurve(to: CGPoint(x: 0.64725*width, y: 0.40604*height), control1: CGPoint(x: 0.55372*width, y: 0.36847*height), control2: CGPoint(x: 0.60625*width, y: 0.38638*height))
        path.addCurve(to: CGPoint(x: 0.69367*width, y: 0.43609*height), control1: CGPoint(x: 0.66849*width, y: 0.41623*height), control2: CGPoint(x: 0.68664*width, y: 0.42689*height))
        path.addCurve(to: CGPoint(x: 0.69486*width, y: 0.44855*height), control1: CGPoint(x: 0.69718*width, y: 0.44069*height), control2: CGPoint(x: 0.69792*width, y: 0.44492*height))
        path.addCurve(to: CGPoint(x: 0.67319*width, y: 0.45739*height), control1: CGPoint(x: 0.6918*width, y: 0.45217*height), control2: CGPoint(x: 0.68495*width, y: 0.45521*height))
        path.addCurve(to: CGPoint(x: 0.52745*width, y: 0.47867*height), control1: CGPoint(x: 0.63464*width, y: 0.46454*height), control2: CGPoint(x: 0.58318*width, y: 0.47159*height))
        path.addCurve(to: CGPoint(x: 0.35601*width, y: 0.50017*height), control1: CGPoint(x: 0.47168*width, y: 0.48575*height), control2: CGPoint(x: 0.41174*width, y: 0.49286*height))
        path.addCurve(to: CGPoint(x: 0.14242*width, y: 0.54736*height), control1: CGPoint(x: 0.24458*width, y: 0.51478*height), control2: CGPoint(x: 0.15059*width, y: 0.53012*height))
        path.addCurve(to: CGPoint(x: 0.21033*width, y: 0.57804*height), control1: CGPoint(x: 0.13818*width, y: 0.55631*height), control2: CGPoint(x: 0.16684*width, y: 0.56673*height))
        path.addCurve(to: CGPoint(x: 0.36668*width, y: 0.61392*height), control1: CGPoint(x: 0.25381*width, y: 0.58934*height), control2: CGPoint(x: 0.312*width, y: 0.6015*height))
        path.addCurve(to: CGPoint(x: 0.50167*width, y: 0.65131*height), control1: CGPoint(x: 0.42133*width, y: 0.62633*height), control2: CGPoint(x: 0.47245*width, y: 0.639*height))
        path.addCurve(to: CGPoint(x: 0.51389*width, y: 0.68327*height), control1: CGPoint(x: 0.52798*width, y: 0.6624*height), control2: CGPoint(x: 0.53655*width, y: 0.67321*height))
        path.addCurve(to: CGPoint(x: 0.51389*width, y: 0.68335*height), control1: CGPoint(x: 0.51394*width, y: 0.6833*height), control2: CGPoint(x: 0.51395*width, y: 0.68333*height))
        path.addCurve(to: CGPoint(x: 0.51242*width, y: 0.68391*height), control1: CGPoint(x: 0.5134*width, y: 0.68354*height), control2: CGPoint(x: 0.51291*width, y: 0.68372*height))
        path.addCurve(to: CGPoint(x: 0.50566*width, y: 0.68643*height), control1: CGPoint(x: 0.5104*width, y: 0.68476*height), control2: CGPoint(x: 0.50814*width, y: 0.6856*height))
        path.addCurve(to: CGPoint(x: 0.30485*width, y: 0.7433*height), control1: CGPoint(x: 0.47286*width, y: 0.69846*height), control2: CGPoint(x: 0.42891*width, y: 0.71124*height))
        path.addCurve(to: CGPoint(x: 0.30724*width, y: 0.76876*height), control1: CGPoint(x: 0.26818*width, y: 0.75277*height), control2: CGPoint(x: 0.27555*width, y: 0.76114*height))
        path.addCurve(to: CGPoint(x: 0.45591*width, y: 0.78974*height), control1: CGPoint(x: 0.33897*width, y: 0.77638*height), control2: CGPoint(x: 0.39507*width, y: 0.78326*height))
        path.addCurve(to: CGPoint(x: 0.63259*width, y: 0.80829*height), control1: CGPoint(x: 0.51667*width, y: 0.7962*height), control2: CGPoint(x: 0.5823*width, y: 0.80228*height))
        path.addCurve(to: CGPoint(x: 0.71827*width, y: 0.82651*height), control1: CGPoint(x: 0.68289*width, y: 0.81428*height), control2: CGPoint(x: 0.71827*width, y: 0.82025*height))
        path.addLine(to: CGPoint(x: 0.71827*width, y: 0.82653*height))
        path.addLine(to: CGPoint(x: 0.71825*width, y: 0.82654*height))
        path.addCurve(to: CGPoint(x: 0.59979*width, y: 0.84619*height), control1: CGPoint(x: 0.70733*width, y: 0.83344*height), control2: CGPoint(x: 0.66158*width, y: 0.83988*height))
        path.addCurve(to: CGPoint(x: 0.38391*width, y: 0.86506*height), control1: CGPoint(x: 0.53798*width, y: 0.85249*height), control2: CGPoint(x: 0.45985*width, y: 0.85868*height))
        path.addCurve(to: CGPoint(x: 0.18058*width, y: 0.8851*height), control1: CGPoint(x: 0.30791*width, y: 0.87144*height), control2: CGPoint(x: 0.23407*width, y: 0.87802*height))
        path.addCurve(to: CGPoint(x: 0.09946*width, y: 0.90817*height), control1: CGPoint(x: 0.1271*width, y: 0.89219*height), control2: CGPoint(x: 0.09408*width, y: 0.89977*height))
        path.addCurve(to: CGPoint(x: 0.14653*width, y: 0.92401*height), control1: CGPoint(x: 0.10364*width, y: 0.91469*height), control2: CGPoint(x: 0.12018*width, y: 0.91992*height))
        path.addCurve(to: CGPoint(x: 0.25278*width, y: 0.93315*height), control1: CGPoint(x: 0.17288*width, y: 0.92811*height), control2: CGPoint(x: 0.2091*width, y: 0.9311*height))
        path.addCurve(to: CGPoint(x: 0.58316*width, y: 0.9356*height), control1: CGPoint(x: 0.3398*width, y: 0.93723*height), control2: CGPoint(x: 0.45638*width, y: 0.93759*height))
        path.addCurve(to: CGPoint(x: 0.5835*width, y: 0.91403*height), control1: CGPoint(x: 0.55802*width, y: 0.92672*height), control2: CGPoint(x: 0.5618*width, y: 0.91955*height))
        path.addCurve(to: CGPoint(x: 0.69177*width, y: 0.90237*height), control1: CGPoint(x: 0.60535*width, y: 0.90847*height), control2: CGPoint(x: 0.64528*width, y: 0.9046*height))
        path.addCurve(to: CGPoint(x: 0.95794*width, y: 0.90809*height), control1: CGPoint(x: 0.78459*width, y: 0.89791*height), control2: CGPoint(x: 0.90399*width, y: 0.89995*height))
        path.addCurve(to: CGPoint(x: 0.97546*width, y: 0.91778*height), control1: CGPoint(x: 0.98102*width, y: 0.91157*height), control2: CGPoint(x: 0.98577*width, y: 0.91481*height))
        path.addCurve(to: CGPoint(x: 0.90416*width, y: 0.92571*height), control1: CGPoint(x: 0.9652*width, y: 0.92073*height), control2: CGPoint(x: 0.9401*width, y: 0.92338*height))
        path.addCurve(to: CGPoint(x: 0.58712*width, y: 0.93586*height), control1: CGPoint(x: 0.83261*width, y: 0.93034*height), control2: CGPoint(x: 0.71731*width, y: 0.93378*height))
        path.addCurve(to: CGPoint(x: 0.62889*width, y: 0.96235*height), control1: CGPoint(x: 0.59228*width, y: 0.93771*height), control2: CGPoint(x: 0.62294*width, y: 0.9492*height))
        path.addCurve(to: CGPoint(x: 0.51023*width, y: 0.99981*height), control1: CGPoint(x: 0.63508*width, y: 0.97602*height), control2: CGPoint(x: 0.61461*width, y: 0.99154*height))
        path.addCurve(to: CGPoint(x: 0.50807*width, y: 0.99977*height), control1: CGPoint(x: 0.50955*width, y: 0.99986*height), control2: CGPoint(x: 0.50858*width, y: 0.99985*height))
        path.addCurve(to: CGPoint(x: 0.50836*width, y: 0.99955*height), control1: CGPoint(x: 0.50755*width, y: 0.9997*height), control2: CGPoint(x: 0.50768*width, y: 0.9996*height))
        path.addCurve(to: CGPoint(x: 0.6258*width, y: 0.96236*height), control1: CGPoint(x: 0.61141*width, y: 0.99139*height), control2: CGPoint(x: 0.63198*width, y: 0.97602*height))
        path.addCurve(to: CGPoint(x: 0.58404*width, y: 0.93591*height), control1: CGPoint(x: 0.61982*width, y: 0.94915*height), control2: CGPoint(x: 0.5888*width, y: 0.9376*height))
        path.addCurve(to: CGPoint(x: 0.25151*width, y: 0.93344*height), control1: CGPoint(x: 0.45688*width, y: 0.93792*height), control2: CGPoint(x: 0.33942*width, y: 0.93757*height))
        path.addCurve(to: CGPoint(x: 0.14396*width, y: 0.92419*height), control1: CGPoint(x: 0.20737*width, y: 0.93137*height), control2: CGPoint(x: 0.17067*width, y: 0.92835*height))
        path.addCurve(to: CGPoint(x: 0.09637*width, y: 0.90819*height), control1: CGPoint(x: 0.11725*width, y: 0.92004*height), control2: CGPoint(x: 0.10058*width, y: 0.91476*height))
        path.addCurve(to: CGPoint(x: 0.17815*width, y: 0.8849*height), control1: CGPoint(x: 0.09092*width, y: 0.89968*height), control2: CGPoint(x: 0.12441*width, y: 0.89202*height))
        path.addCurve(to: CGPoint(x: 0.38197*width, y: 0.86481*height), control1: CGPoint(x: 0.23188*width, y: 0.87778*height), control2: CGPoint(x: 0.30597*width, y: 0.87119*height))
        path.addCurve(to: CGPoint(x: 0.59762*width, y: 0.84596*height), control1: CGPoint(x: 0.45802*width, y: 0.85842*height), control2: CGPoint(x: 0.53595*width, y: 0.85225*height))
        path.addCurve(to: CGPoint(x: 0.71517*width, y: 0.8265*height), control1: CGPoint(x: 0.65926*width, y: 0.83967*height), control2: CGPoint(x: 0.70438*width, y: 0.83329*height))
        path.addCurve(to: CGPoint(x: 0.63026*width, y: 0.8085*height), control1: CGPoint(x: 0.71512*width, y: 0.82037*height), control2: CGPoint(x: 0.68044*width, y: 0.81448*height))
        path.addCurve(to: CGPoint(x: 0.4537*width, y: 0.78996*height), control1: CGPoint(x: 0.58002*width, y: 0.8025*height), control2: CGPoint(x: 0.5147*width, y: 0.79645*height))
        path.addCurve(to: CGPoint(x: 0.3044*width, y: 0.76889*height), control1: CGPoint(x: 0.3928*width, y: 0.78348*height), control2: CGPoint(x: 0.33636*width, y: 0.77657*height))
        path.addCurve(to: CGPoint(x: 0.30198*width, y: 0.74317*height), control1: CGPoint(x: 0.27241*width, y: 0.7612*height), control2: CGPoint(x: 0.26497*width, y: 0.75274*height))
        path.addCurve(to: CGPoint(x: 0.50221*width, y: 0.68652*height), control1: CGPoint(x: 0.42543*width, y: 0.71128*height), control2: CGPoint(x: 0.4695*width, y: 0.69848*height))
        path.addCurve(to: CGPoint(x: 0.50227*width, y: 0.68649*height), control1: CGPoint(x: 0.50222*width, y: 0.68651*height), control2: CGPoint(x: 0.50224*width, y: 0.6865*height))
        path.addCurve(to: CGPoint(x: 0.50271*width, y: 0.68634*height), control1: CGPoint(x: 0.50242*width, y: 0.68644*height), control2: CGPoint(x: 0.50256*width, y: 0.68639*height))
        path.addCurve(to: CGPoint(x: 0.50938*width, y: 0.68385*height), control1: CGPoint(x: 0.50498*width, y: 0.68551*height), control2: CGPoint(x: 0.50719*width, y: 0.68468*height))
        path.addCurve(to: CGPoint(x: 0.49867*width, y: 0.65139*height), control1: CGPoint(x: 0.53375*width, y: 0.67366*height), control2: CGPoint(x: 0.52548*width, y: 0.66269*height))
        path.addCurve(to: CGPoint(x: 0.36386*width, y: 0.61405*height), control1: CGPoint(x: 0.46952*width, y: 0.63911*height), control2: CGPoint(x: 0.4185*width, y: 0.62647*height))
        path.addCurve(to: CGPoint(x: 0.20746*width, y: 0.57816*height), control1: CGPoint(x: 0.30925*width, y: 0.60165*height), control2: CGPoint(x: 0.25097*width, y: 0.58947*height))
        path.addCurve(to: CGPoint(x: 0.13933*width, y: 0.54735*height), control1: CGPoint(x: 0.16394*width, y: 0.56685*height), control2: CGPoint(x: 0.13505*width, y: 0.55637*height))
        path.addCurve(to: CGPoint(x: 0.35358*width, y: 0.49997*height), control1: CGPoint(x: 0.14756*width, y: 0.53*height), control2: CGPoint(x: 0.24211*width, y: 0.51459*height))
        path.addCurve(to: CGPoint(x: 0.52506*width, y: 0.47846*height), control1: CGPoint(x: 0.40931*width, y: 0.49266*height), control2: CGPoint(x: 0.46941*width, y: 0.48553*height))
        path.addCurve(to: CGPoint(x: 0.67048*width, y: 0.45724*height), control1: CGPoint(x: 0.58076*width, y: 0.47139*height), control2: CGPoint(x: 0.63208*width, y: 0.46436*height))
        path.addCurve(to: CGPoint(x: 0.69178*width, y: 0.44852*height), control1: CGPoint(x: 0.68193*width, y: 0.45511*height), control2: CGPoint(x: 0.68874*width, y: 0.45213*height))
        path.addCurve(to: CGPoint(x: 0.69058*width, y: 0.43611*height), control1: CGPoint(x: 0.69481*width, y: 0.44492*height), control2: CGPoint(x: 0.69409*width, y: 0.4407*height))
        path.addCurve(to: CGPoint(x: 0.64422*width, y: 0.40611*height), control1: CGPoint(x: 0.68357*width, y: 0.42694*height), control2: CGPoint(x: 0.66545*width, y: 0.41629*height))
        path.addCurve(to: CGPoint(x: 0.54421*width, y: 0.36632*height), control1: CGPoint(x: 0.60298*width, y: 0.38633*height), control2: CGPoint(x: 0.55003*width, y: 0.36832*height))
        path.addCurve(to: CGPoint(x: 0.18365*width, y: 0.36345*height), control1: CGPoint(x: 0.41689*width, y: 0.36832*height), control2: CGPoint(x: 0.2855*width, y: 0.36777*height))
        path.addCurve(to: CGPoint(x: 0.00039*width, y: 0.3378*height), control1: CGPoint(x: 0.08134*width, y: 0.35911*height), control2: CGPoint(x: 0.00882*width, y: 0.35096*height))
        path.addCurve(to: CGPoint(x: 0.13011*width, y: 0.31579*height), control1: CGPoint(x: -0.00508*width, y: 0.32926*height), control2: CGPoint(x: 0.04779*width, y: 0.32212*height))
        path.addCurve(to: CGPoint(x: 0.4388*width, y: 0.29858*height), control1: CGPoint(x: 0.21247*width, y: 0.30946*height), control2: CGPoint(x: 0.3247*width, y: 0.30392*height))
        path.addCurve(to: CGPoint(x: 0.75925*width, y: 0.28261*height), control1: CGPoint(x: 0.55298*width, y: 0.29324*height), control2: CGPoint(x: 0.66902*width, y: 0.28811*height))
        path.addCurve(to: CGPoint(x: 0.87158*width, y: 0.27401*height), control1: CGPoint(x: 0.80436*width, y: 0.27985*height), control2: CGPoint(x: 0.84294*width, y: 0.27701*height))
        path.addCurve(to: CGPoint(x: 0.92415*width, y: 0.26448*height), control1: CGPoint(x: 0.90018*width, y: 0.27101*height), control2: CGPoint(x: 0.91878*width, y: 0.26786*height))
        path.addCurve(to: CGPoint(x: 0.88961*width, y: 0.25578*height), control1: CGPoint(x: 0.92412*width, y: 0.26144*height), control2: CGPoint(x: 0.91159*width, y: 0.25856*height))
        path.addCurve(to: CGPoint(x: 0.79866*width, y: 0.24767*height), control1: CGPoint(x: 0.8676*width, y: 0.253*height), control2: CGPoint(x: 0.8362*width, y: 0.25032*height))
        path.addCurve(to: CGPoint(x: 0.52759*width, y: 0.23154*height), control1: CGPoint(x: 0.72356*width, y: 0.24236*height), control2: CGPoint(x: 0.62437*width, y: 0.2372*height))
        path.addCurve(to: CGPoint(x: 0.27205*width, y: 0.21251*height), control1: CGPoint(x: 0.43092*width, y: 0.22589*height), control2: CGPoint(x: 0.33673*width, y: 0.21975*height))
        path.addCurve(to: CGPoint(x: 0.19353*width, y: 0.18682*height), control1: CGPoint(x: 0.20732*width, y: 0.20527*height), control2: CGPoint(x: 0.17204*width, y: 0.19691*height))
        path.addCurve(to: CGPoint(x: 0.39644*width, y: 0.15067*height), control1: CGPoint(x: 0.2331*width, y: 0.16825*height), control2: CGPoint(x: 0.3173*width, y: 0.15824*height))
        path.addCurve(to: CGPoint(x: 0.50495*width, y: 0.14042*height), control1: CGPoint(x: 0.43607*width, y: 0.14689*height), control2: CGPoint(x: 0.47416*width, y: 0.14374*height))
        path.addCurve(to: CGPoint(x: 0.56854*width, y: 0.12931*height), control1: CGPoint(x: 0.53567*width, y: 0.13711*height), control2: CGPoint(x: 0.55885*width, y: 0.13366*height))
        path.addCurve(to: CGPoint(x: 0.53426*width, y: 0.11106*height), control1: CGPoint(x: 0.58123*width, y: 0.12361*height), control2: CGPoint(x: 0.56498*width, y: 0.1175*height))
        path.addCurve(to: CGPoint(x: 0.41403*width, y: 0.09092*height), control1: CGPoint(x: 0.50355*width, y: 0.10462*height), control2: CGPoint(x: 0.45853*width, y: 0.09788*height))
        path.addCurve(to: CGPoint(x: 0.29729*width, y: 0.06949*height), control1: CGPoint(x: 0.36956*width, y: 0.08396*height), control2: CGPoint(x: 0.32563*width, y: 0.07679*height))
        path.addCurve(to: CGPoint(x: 0.27404*width, y: 0.04732*height), control1: CGPoint(x: 0.26894*width, y: 0.0622*height), control2: CGPoint(x: 0.25613*width, y: 0.05477*height))
        path.addCurve(to: CGPoint(x: 0.34445*width, y: 0.03235*height), control1: CGPoint(x: 0.28687*width, y: 0.04198*height), control2: CGPoint(x: 0.31364*width, y: 0.03698*height))
        path.addCurve(to: CGPoint(x: 0.43934*width, y: 0.01949*height), control1: CGPoint(x: 0.37524*width, y: 0.02772*height), control2: CGPoint(x: 0.41019*width, y: 0.02342*height))
        path.addCurve(to: CGPoint(x: 0.49996*width, y: 0.00879*height), control1: CGPoint(x: 0.46858*width, y: 0.01555*height), control2: CGPoint(x: 0.49193*width, y: 0.01199*height))
        path.addCurve(to: CGPoint(x: 0.49939*width, y: 0.00428*height), control1: CGPoint(x: 0.50397*width, y: 0.00719*height), control2: CGPoint(x: 0.50414*width, y: 0.00569*height))
        path.addCurve(to: CGPoint(x: 0.46884*width, y: 0.00029*height), control1: CGPoint(x: 0.49464*width, y: 0.00288*height), control2: CGPoint(x: 0.48491*width, y: 0.00154*height))
        path.addCurve(to: CGPoint(x: 0.46853*width, y: 0.00006*height), control1: CGPoint(x: 0.46815*width, y: 0.00024*height), control2: CGPoint(x: 0.46802*width, y: 0.00014*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.95539*width, y: 0.90827*height))
        path.addCurve(to: CGPoint(x: 0.69307*width, y: 0.90266*height), control1: CGPoint(x: 0.90252*width, y: 0.9003*height), control2: CGPoint(x: 0.78492*width, y: 0.89825*height))
        path.addCurve(to: CGPoint(x: 0.58637*width, y: 0.91415*height), control1: CGPoint(x: 0.64721*width, y: 0.90486*height), control2: CGPoint(x: 0.60789*width, y: 0.90867*height))
        path.addCurve(to: CGPoint(x: 0.58625*width, y: 0.93555*height), control1: CGPoint(x: 0.56496*width, y: 0.91959*height), control2: CGPoint(x: 0.56112*width, y: 0.9267*height))
        path.addCurve(to: CGPoint(x: 0.90253*width, y: 0.92543*height), control1: CGPoint(x: 0.71648*width, y: 0.93347*height), control2: CGPoint(x: 0.83144*width, y: 0.93004*height))
        path.addCurve(to: CGPoint(x: 0.97255*width, y: 0.91767*height), control1: CGPoint(x: 0.9382*width, y: 0.92312*height), control2: CGPoint(x: 0.96262*width, y: 0.92052*height))
        path.addCurve(to: CGPoint(x: 0.95539*width, y: 0.90827*height), control1: CGPoint(x: 0.98244*width, y: 0.91482*height), control2: CGPoint(x: 0.97804*width, y: 0.91169*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.85178*width, y: 0.32015*height))
        path.addCurve(to: CGPoint(x: 0.6829*width, y: 0.32493*height), control1: CGPoint(x: 0.79722*width, y: 0.31926*height), control2: CGPoint(x: 0.73665*width, y: 0.32109*height))
        path.addCurve(to: CGPoint(x: 0.54641*width, y: 0.36596*height), control1: CGPoint(x: 0.57569*width, y: 0.3326*height), control2: CGPoint(x: 0.49617*width, y: 0.34822*height))
        path.addCurve(to: CGPoint(x: 0.88752*width, y: 0.35296*height), control1: CGPoint(x: 0.6766*width, y: 0.36387*height), control2: CGPoint(x: 0.80235*width, y: 0.3591*height))
        path.addCurve(to: CGPoint(x: 0.98039*width, y: 0.34286*height), control1: CGPoint(x: 0.93026*width, y: 0.34988*height), control2: CGPoint(x: 0.96268*width, y: 0.34646*height))
        path.addCurve(to: CGPoint(x: 0.98504*width, y: 0.33173*height), control1: CGPoint(x: 0.99807*width, y: 0.33928*height), control2: CGPoint(x: 1.00109*width, y: 0.33552*height))
        path.addCurve(to: CGPoint(x: 0.85178*width, y: 0.32015*height), control1: CGPoint(x: 0.95495*width, y: 0.32464*height), control2: CGPoint(x: 0.90625*width, y: 0.32104*height))
        path.closeSubpath()
        return path
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
