//
//  delete alert.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 30/11/25.
//

import SwiftUI

struct DeleteAlert: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            VStack(alignment: .leading, spacing: 10) {
                // Title
                Text("Delete this moment?")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Message
                Text("This action is permanent and can't be undone.")
                    .font(.callout)
                    .foregroundColor(.white)
            }
            .padding(8)
            .padding(.bottom, 24)
            
            // Buttons (side by side)
            HStack(spacing: 12) {
                // Delete Button (left)
                Button {
                } label: {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .cornerRadius(25)
                }
                .glassEffect(.regular.tint(.black.opacity(0.20)))
                
                // Keep Button (right, with gradient)
                Button {
                } label: {
                    Text("Keep")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8376DB"),
                                    Color(hex: "705AB1")
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 100
                            )
                        )
                        .cornerRadius(25)
                }
            }
        }
        .frame(width: 300)
        .padding(14)
        .cornerRadius(20)
        .glassEffect(.regular.tint(.black.opacity(0.50)), in: .rect(cornerRadius: 20.0))
        
    }
}

#Preview {
    ZStack {
        Image("librarySample1")
            .resizable()
            .frame(maxWidth: .infinity)
        DeleteAlert()
    }
}
