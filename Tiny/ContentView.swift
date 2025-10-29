//
//  ContentView.swift
//  tiny
//
//  Created by Destu Cikal Ramdani on 25/10/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            ZStack {
                if colorScheme == .dark {
                    Image(.backgroundDarkDummy)
                        .resizable()
                        .scaledToFill()
                }

                StartListeningButton()
            }
        } 
        .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
