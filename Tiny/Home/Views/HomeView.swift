//
//  HomeView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 30/10/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var homeVM: HomeViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            HStack {
                Text("Hello, Mrs. \(homeVM.displayName)")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(hex: "141414"))
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.title)
            }
            
            PregnancyAgeView(ageWeeks: homeVM.displayAgeWeeks, ageDays: homeVM.displayAgeDays)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Today, I want to")
                    .font(.title3)
                    .bold()
                
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
            .frame(maxWidth: .infinity)
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)

        Spacer()
    }
}

#Preview {
    let age = PregnancyAge(ageWeeks: 12, ageDays: 4)
    let homeData = HomeData(name: "Mil", pregnancyAge: age)
    HomeView(homeVM: .init(homeData: homeData))
}
