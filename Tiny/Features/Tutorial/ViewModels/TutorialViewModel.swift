//
//  TutorialViewModel.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 25/11/25.
//
import Foundation
internal import Combine

class TutorialViewModel: ObservableObject {
    @Published var activeTutorial: TutorialContext?
    
    func showInitialTutorialIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "hasShownInitialTutorial") {
            activeTutorial = .initial
        }
    }
    
    func showListeningTutorialIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "hasShownListeningTutorial") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.activeTutorial = .listening
            }
        }
    }
    
    func dismissTutorial(context: TutorialContext) {
        switch context {
        case .initial:
            UserDefaults.standard.set(true, forKey: "hasShownInitialTutorial")
        case .listening:
            UserDefaults.standard.set(true, forKey: "hasShownListeningTutorial")
        }
        activeTutorial = nil
    }
}
