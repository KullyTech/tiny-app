//
//  FeatureCard.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 29/10/25.
//

import SwiftUI

struct BackgroundCard: View {
    let color1: Color
    let color2: Color
    let logo: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: color1, location: 0.00),
                    Gradient.Stop(color: color2, location: 1.00)
                ],
                startPoint: UnitPoint(x: 0.09, y: -0.12),
                endPoint: UnitPoint(x: 1.03, y: 1)
            )
            .frame(width: 168, height: 120)
            
            Image(logo)
                .frame(width: 103, height: 53.54)
                .offset(x: 48, y: 20)
        }
    }
}

struct FeatureCard: View {
    let title: String
    let titleColor: Color
    let logo: String
    let color1: Color
    let color2: Color
    
    var body: some View {
        GlassEffectContainer(spacing: 40) {
            ZStack {
                BackgroundCard(color1: color1, color2: color2, logo: logo)
                    .cornerRadius(16)
                VStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(Font.Weight.bold)
                        .foregroundColor(titleColor)
                }
                .padding(16)
                .frame(width: 168, height: 120, alignment: .topLeading)
                .shadow(color: .black.opacity(0.12), radius: 7, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.95, green: 0.81, blue: 0.78), lineWidth: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        .blur(radius: 2)
                        .offset(x: 0, y: 0)
                        .mask(RoundedRectangle(cornerRadius: 16))
                )
            }
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
        }
    }
}

struct FeatureCardGroup: View {
    var body: some View {
        HStack(spacing: 20) {
            FeatureCard(title: "Listen to baby's heartbeat",
                        titleColor: Color(hex: "95436F"),
                        logo: "soundMemo",
                        color1: Color(hex: "FFDE90"),
                        color2: Color(hex: "FFA8E2"))
            
            FeatureCard(title: "Feels baby's heartbeat",
                        titleColor: Color(hex: "513C8A"),
                        logo: "heartBeat",
                        color1: Color(hex: "FDBBEB"),
                        color2: Color(hex: "9595E8"))
        }
    }
}

#Preview {
    FeatureCardGroup()
}
