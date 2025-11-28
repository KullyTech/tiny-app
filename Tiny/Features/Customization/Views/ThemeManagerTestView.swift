//
//  ThemeManagerTestView.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 28/11/25.
//

import SwiftUI

struct ThemeManagerTestView: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Theme Manager Test")
                .font(.title)
                .padding()
            
            // Display current selections
            VStack(alignment: .leading, spacing: 10) {
                Text("Current Orb Style: \(themeManager.selectedOrbStyle.displayName)")
                    .font(.headline)
                
                Text("Current Background: \(themeManager.selectedBackground.displayName)")
                    .font(.headline)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
            // Test orb style changes
            VStack {
                Text("Change Orb Style:")
                    .font(.subheadline)
                
                HStack {
                    ForEach(OrbStyles.allCases) { style in
                        Button(style.displayName) {
                            themeManager.selectedOrbStyle = style
                            print("✅ Orb style changed to: \(style.displayName)")
                        }
                        .padding()
                        .background(themeManager.selectedOrbStyle == style ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Test background changes
            VStack {
                Text("Change Background:")
                    .font(.subheadline)
                
                HStack {
                    ForEach(BackgroundTheme.allCases) { bg in
                        Button(bg.displayName) {
                            themeManager.selectedBackground = bg
                            print("✅ Background changed to: \(bg.displayName)")
                        }
                        .padding()
                        .background(themeManager.selectedBackground == bg ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Test persistence
            Button("Clear UserDefaults (Reset)") {
                UserDefaults.standard.removeObject(forKey: "selectedOrbStyle")
                UserDefaults.standard.removeObject(forKey: "selectedBackground")
                print("🗑️ UserDefaults cleared - restart app to test defaults")
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ThemeManagerTestView()
}
