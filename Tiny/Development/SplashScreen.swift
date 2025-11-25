//
//  SplashScreen.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 24/11/25.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isShowingSplashScreen: Bool
    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            Image("bgSplashScreen")
                .resizable()
                .scaledToFill()

            Image("titleSplashScreen")
                .resizable()
                .scaledToFill()
                .frame(width: animate ? 100 :80, height: animate ? 100 : 80) // Animate size
                .opacity(animate ? 1 : 0.5) // Animate opacity
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isShowingSplashScreen = false
                }
            }
        }
    }
}

#Preview {
    SplashScreen(isShowingSplashScreen: .constant(true))
        .preferredColorScheme(.dark)
}
