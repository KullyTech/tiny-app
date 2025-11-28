//
//  ThemeManager.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 28/11/25.
//

import Foundation
import SwiftUI
internal import Combine

class ThemeManager: ObservableObject {
    @Published var selectedOrbStyle: OrbStyles {
        didSet {
            saveOrbStyle()
        }
    }
    
    @Published var selectedBackground: BackgroundTheme {
        didSet {
            saveBackground()
        }
    }
    
    private let orbStyleKey = "selectedOrbStyle"
    private let backgroundKey = "selectedBackground"
    
    init() {
        if let savedOrbStyle = UserDefaults.standard.string(forKey: orbStyleKey),
           let orbStyle = OrbStyles(rawValue: savedOrbStyle) {
            self.selectedOrbStyle = orbStyle
        } else {
            self.selectedOrbStyle = .yellow
        }
        
        if let savedBackground = UserDefaults.standard.string(forKey: backgroundKey),
           let background = BackgroundTheme(rawValue: savedBackground) {
            self.selectedBackground = background
        } else {
            self.selectedBackground = .purple
        }
    }
    
    private func saveOrbStyle() {
        UserDefaults.standard.set(selectedOrbStyle.rawValue, forKey: orbStyleKey)
    }
    
    private func saveBackground() {
        UserDefaults.standard.set(selectedBackground.rawValue, forKey: backgroundKey)
    }
}
