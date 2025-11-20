//
//  OrbStylePicker.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 21/11/25.
//

import SwiftUI

struct OrbStylePicker: View {
    @Binding var selectedStyle: OrbStyles
    
    var body: some View {
        VStack(spacing: 40) {
            // Large central orb
            AnimatedOrbView(size: 200, style: selectedStyle)
                .frame(width: 200, height: 200)
            
            // Horizontal scrollable style names
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(OrbStyles.allCases) { style in
                        Button(
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedStyle = style
                                }
                            },
                            label: {
                                Text(style.displayName)
                                    .font(.title3)
                                    .fontWeight(selectedStyle == style ? .bold : .medium)
                                    .foregroundColor(selectedStyle == style ? .white : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedStyle == style ? style.glowColor.opacity(0.3) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedStyle == style ? style.glowColor : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        )
                        .buttonStyle(.plain)
                        .scaleEffect(selectedStyle == style ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedStyle == style)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 50)
        }
    }
}

#Preview {
    @Previewable @State var selectedStyle: OrbStyles = .ocean
    
    VStack {
        OrbStylePicker(selectedStyle: $selectedStyle)
        Spacer()
    }
    .padding()
    .background(Color.black.ignoresSafeArea())
}
