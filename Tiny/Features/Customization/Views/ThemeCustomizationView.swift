//
//  ThemeCustomizationView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 28/11/25.
//

import SwiftUI

struct ThemeCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: CustomizationTab = .sphere
    
    enum CustomizationTab: String, CaseIterable {
        case sphere = "Sphere"
        case background = "Background"
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            Image(themeManager.selectedBackground.imageName)
                .resizable()
                .ignoresSafeArea()
                .opacity(0.6)
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    Text("Theme")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                // Preview Orb
                ZStack {
                    AnimatedOrbView(size: 200)
                        .environmentObject(themeManager)
                    
                    BokehEffectView(amplitude: .constant(0.6))
                        .environmentObject(themeManager)
                }
                .frame(width: 200, height: 200)
                
                Spacer()
                
                // Tab Selector
                HStack(spacing: 0) {
                    ForEach(CustomizationTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.headline)
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    selectedTab == tab ?
                                    Color.white.opacity(0.2) : Color.clear
                                )
                        }
                    }
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(25)
                .padding(.horizontal)
                
                // Options Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        if selectedTab == .sphere {
                            ForEach(OrbStyles.allCases) { style in
                                OrbOptionButton(
                                    style: style,
                                    isSelected: themeManager.selectedOrbStyle == style,
                                    action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            themeManager.selectedOrbStyle = style
                                        }
                                    }
                                )
                            }
                        } else {
                            ForEach(BackgroundTheme.allCases) { background in
                                BackgroundOptionButton(
                                    background: background,
                                    isSelected: themeManager.selectedBackground == background,
                                    action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            themeManager.selectedBackground = background
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Orb Option Button
struct OrbOptionButton: View {
    let style: OrbStyles
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                AnimatedOrbView(size: 80, style: style)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Background Option Button
struct BackgroundOptionButton: View {
    let background: BackgroundTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        ImagePaint(
                            image: Image(background.imageName),
                            scale: 0.3
                        )
                    )
                    .frame(width: 80, height: 80)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ThemeCustomizationView()
        .environmentObject(ThemeManager())
}
