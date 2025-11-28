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
                .opacity(1)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                    .glassEffect(.clear)
                    
                    Spacer()
                    
                    Text("Theme")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear.frame(width: 50, height: 50)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Preview Orb - Centered in remaining space
                Spacer()
                
                ZStack {
                    AnimatedOrbView(size: 240)
                        .environmentObject(themeManager)
                    
                    BokehEffectView(amplitude: .constant(0.6))
                        .environmentObject(themeManager)
                }
                .frame(width: 240, height: 240)
                
                Spacer()
                
                // Bottom Sheet
                VStack(spacing: 0) {
                    // Segmented Control
                    HStack(spacing: 0) {
                        ForEach(CustomizationTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? .white : .tinyViolet)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedTab == tab ? Color.tinyViolet : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Options - Horizontal scroll with selected item prominent
                    ScrollViewReader { proxy in
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
                                        .id(style.id)
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
                                        .id(background.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 30)
                        }
                        .onChange(of: themeManager.selectedOrbStyle) { _, newValue in
                            withAnimation {
                                proxy.scrollTo(newValue.id, anchor: .center)
                            }
                        }
                        .onChange(of: themeManager.selectedBackground) { _, newValue in
                            withAnimation {
                                proxy.scrollTo(newValue.id, anchor: .center)
                            }
                        }
                    }
                    .frame(height: 240)
                }
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white.opacity(0.05))
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial.opacity(0.07))
                        )
                        .ignoresSafeArea(.all)
                )
                .padding(.bottom, 0)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Orb Option Button - Selected is MUCH larger
struct OrbOptionButton: View {
    let style: OrbStyles
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // The orb itself
                AnimatedOrbView(size: isSelected ? 120 : 90, style: style)
                
                // Subtle glow for selected
                if isSelected {
                    Circle()
                        .fill(style.glowColor.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                }
            }
            .frame(width: isSelected ? 160 : 100, height: isSelected ? 160 : 100)
            .opacity(isSelected ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

// Background Option Button - Selected is MUCH larger
struct BackgroundOptionButton: View {
    let background: BackgroundTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background preview circle
                Circle()
                    .fill(
                        ImagePaint(
                            image: Image(background.imageName),
                            scale: isSelected ? 0.25 : 0.35
                        )
                    )
                    .frame(width: isSelected ? 120 : 90, height: isSelected ? 120 : 90)
                
                // Border for selected
                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 3)
                        .frame(width: isSelected ? 120 : 95, height: isSelected ? 120 : 95)
                }
                
                // Subtle outer glow
                if isSelected {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: 120, height: 120)
                        .blur(radius: 10)
                }
            }
            .frame(width: isSelected ? 120 : 100, height: isSelected ? 120 : 100)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ThemeCustomizationView()
        .environmentObject(ThemeManager())
}
