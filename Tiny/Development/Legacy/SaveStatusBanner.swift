//
//  SaveStatusBanner.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 21/11/25.
//

import SwiftUI

struct SaveStatusBanner: View {
    let statusIcon: String
    let headerStatus: String
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .resizable()
                .frame(width: 28, height: 28)
                .fontWeight(.bold)
                .padding(5)
            VStack(alignment: .leading) {
                Text(headerStatus)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.callout)
            }
        }
        .clipShape(Rectangle())
        .foregroundStyle(Color(.white))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .cornerRadius(24)
        .glassEffect(.clear, in: .rect(cornerRadius: 24.0))
    }
}

extension View {
    func topBanner(isPresented: Binding<Bool>, statusIcon: String, headerStatus: String, message: String) -> some View {
        self.overlay(
            VStack {
                if isPresented.wrappedValue {
                    SaveStatusBanner(statusIcon: statusIcon, headerStatus: headerStatus, message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
                Spacer()
            }
            .animation(.spring(), value: isPresented.wrappedValue)
        )
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        SaveStatusBanner(statusIcon: "checkmark.circle", headerStatus: "Saved!", message: "Your recording is saved on timeline.")
    }
}
