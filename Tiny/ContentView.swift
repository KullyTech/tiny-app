//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        SpriteView(scene: LiveListenView())
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
