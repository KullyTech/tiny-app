//
//  FolderCardView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 02/11/25.
//

import SwiftUI

struct FolderCardView: View {
    let library: LibraryModel

    private func computedOffset(for index: Int) -> CGSize {
        let xOffsets: [CGFloat] = [15, -20  , 20]   // right, left, right
        let yOffsets: [CGFloat] = [-10, 0, 18] // above, middle, bottom

        guard index < xOffsets.count else { return .zero }
        return CGSize(width: xOffsets[index], height: yOffsets[index])
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("folderBackground"))
                .frame(width: 160, height: 160)

            // Stacked preview images
            ZStack {
                ForEach(Array(library.imageURL.prefix(3).enumerated()), id: \.offset) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 100)
                        .cornerRadius(12)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? 8 : -8))
                        .offset(computedOffset(for: index))
                }
            }
            .offset(y: -30)

            // Bottom pocket overlay
            RoundedRectangle(cornerRadius: 20)
                .glassEffect(
                    .clear.tint(Color("folderBackground").opacity(0.6)),
                    in: .rect(cornerRadius: 20)
                )
                .frame(height: 70)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        Text(library.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        HStack(spacing: 4) {
                            Text("Week \(library.week)")
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "play.square.stack")
                                .foregroundColor(.white)
                                .font(.caption2)
                            Text("\(library.clipCount)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10),
                    alignment: .bottomLeading
                )
        }
        .frame(width: 160, height: 167)
    }
}

#Preview {
    FolderCardView(
        library: LibraryModel(
            imageURL: ["librarySample1", "librarySample2", "librarySample3"],
            id: UUID().uuidString,
            name: "Library One",
            week: 3,
            clipCount: 4
        )
    )
}
