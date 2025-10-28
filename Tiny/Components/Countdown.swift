//
//  Countdown.swift
//  Tiny
//
//  Created by Benedictus Yogatama Favian Satyajati on 28/10/25.
//

/*
 
== Developer Notes ==
 
    DESCRIPTION:
    This is a component that will display a countdown when called inside a view.
 
    USAGE:
    Countdown(maxCount: 5){
        function()
    }
 
== Developer Notes ==
 
*/

import SwiftUI

struct Countdown: View {
    let maxCount: Int
    @State private var currentCount: Int
    @State private var timer: Timer?

    var onCountdownComplete: (() -> Void)?
    
    init (maxCount: Int = 5, onCountdownComplete: (() -> Void)? = nil) {
        self.maxCount = maxCount
        self._currentCount = State(initialValue: maxCount)
        self.onCountdownComplete = onCountdownComplete
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Starting in")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            HStack(spacing: 0) {
                Text("\(currentCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                Text("...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            stopCountdown()
        }
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                if currentCount > 1 {
                    currentCount -= 1
                } else {
                    stopCountdown()
                    onCountdownComplete?()
                }
            }
        }
    }
    
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    Countdown(maxCount: 5) {
        print("Countdown Complete")
    }
}
