//
//  LibraryDetailView.swift
//  Tiny
//

import SwiftUI

struct LibraryDetailView: View {
    let library: LibraryModel

    var body: some View {
        VStack(spacing: 16) {
            Text(library.name)
                .font(.largeTitle.bold())

            Text("Week \(library.week)")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Contains \(library.clipCount) clips")
                .font(.subheadline)

            Spacer()
        }
        .padding()
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LibraryDetailView(
        library: LibraryModel(
            imageURL: ["librarySample1", "librarySample2", "librarySample3"],
            id: UUID().uuidString,
            name: "Library One",
            week: 3,
            clipCount: 4
        )
    )
}
