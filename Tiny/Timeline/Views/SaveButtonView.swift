//
//  SaveButtonView.swift
//  Tiny
//
//  Created by Tm Revanza Narendra Pradipta on 19/11/25.
//

import SwiftUI

struct SaveButtonView: View {
    var body: some View {
        Button {} label: {
            Image(systemName: "book.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 77, height: 77)
                .clipShape(Circle())
        }
        .glassEffect(.clear)
    }
}

#Preview {
    ZStack {
        Color.black
        SaveButtonView()
    }
}
