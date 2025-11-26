//
//  RoleButton.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 26/11/25.
//

import SwiftUI

struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .padding(.all, 28)
                    .overlay {
                        Circle()
                            .stroke(
                                isSelected ? Color("tinyViolet") : Color.clear,
                                lineWidth: isSelected ? 5 : 0
                            )
                    }
                    .glassEffect()
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(isSelected ? Color("tinyViolet") : Color.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

//#Preview{
//    RoleSelectionView()
//        .preferredColorScheme(.dark)
//}
