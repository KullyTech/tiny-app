//
//  FolderCardView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 02/11/25.
//

import SwiftUI

struct FolderTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.1*width, y: 0.00532*height))
        path.addLine(to: CGPoint(x: 0.35*width, y: 0.00532*height))
        path.addCurve(to: CGPoint(x: 0.42704*width, y: 0.05324*height), control1: CGPoint(x: 0.3764*width, y: 0.00532*height), control2: CGPoint(x: 0.40503*width, y: 0.02358*height))
        path.addCurve(to: CGPoint(x: 0.46406*width, y: 0.16755*height), control1: CGPoint(x: 0.44906*width, y: 0.08292*height), control2: CGPoint(x: 0.46406*width, y: 0.12342*height))
        path.addCurve(to: CGPoint(x: 0.56563*width, y: 0.34043*height), control1: CGPoint(x: 0.46406*width, y: 0.26303*height), control2: CGPoint(x: 0.50953*width, y: 0.34043*height))
        path.addLine(to: CGPoint(x: 0.9*width, y: 0.34043*height))
        path.addCurve(to: CGPoint(x: 0.99687*width, y: 0.50532*height), control1: CGPoint(x: 0.9535*width, y: 0.34043*height), control2: CGPoint(x: 0.99687*width, y: 0.41425*height))
        path.addLine(to: CGPoint(x: 0.99687*width, y: 0.82979*height))
        path.addCurve(to: CGPoint(x: 0.9*width, y: 0.99468*height), control1: CGPoint(x: 0.99687*width, y: 0.92086*height), control2: CGPoint(x: 0.9535*width, y: 0.99468*height))
        path.addLine(to: CGPoint(x: 0.1*width, y: 0.99468*height))
        path.addCurve(to: CGPoint(x: 0.00313*width, y: 0.82979*height), control1: CGPoint(x: 0.0465*width, y: 0.99468*height), control2: CGPoint(x: 0.00313*width, y: 0.92086*height))
        path.addLine(to: CGPoint(x: 0.00313*width, y: 0.17021*height))
        path.addCurve(to: CGPoint(x: 0.1*width, y: 0.00532*height), control1: CGPoint(x: 0.00313*width, y: 0.07914*height), control2: CGPoint(x: 0.0465*width, y: 0.00532*height))
        path.closeSubpath()
        return path
    }
}

struct FolderShapeButton: View {
    let library: LibraryModel
    let onTap: () -> Void

    private func computedOffset(for index: Int) -> CGSize {
        let xOffsets: [CGFloat] = [15, -20, 20]   // right, left, right
        let yOffsets: [CGFloat] = [-10, 0, 18] // above, middle, bottom

        guard index < xOffsets.count else { return .zero }
        return CGSize(width: xOffsets[index], height: yOffsets[index])
    }
    private func computedRotation(for index: Int) -> Angle {
        let rotations: [Double] = [10, -20, 10] // manually tweakable rotation per image

        guard index < rotations.count else { return .degrees(0) }
        return .degrees(rotations[index])
    }

    var body: some View {
        Button(
            action: {
                onTap()
            },
            label: {
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
                                .rotationEffect(computedRotation(for: index))
                                .offset(computedOffset(for: index))
                        }
                    }
                    .offset(y: -30)

                    // Bottom pocket overlay
                    FolderTabShape()
                        .glassEffect(
                            .clear
                                .tint(Color("folderBackground").opacity(0.6)),
                            in: FolderTabShape()
                        )
                        .frame(width: 160, height: 88)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                Text(library.name)
                                    .font(.default)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
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
                                .padding(.bottom, 10)
                                .frame(width: 160),
                            alignment: .bottomLeading
                        )
                }
            }
        )
        .buttonStyle(.plain)
    }
}

#Preview {
    FolderShapeButton(
        library: LibraryModel(
            imageURL: ["librarySample1", "librarySample2", "librarySample3"],
            id: UUID().uuidString,
            name: "Library One",
            week: 3,
            clipCount: 4
        ), onTap: {}
    )
}
