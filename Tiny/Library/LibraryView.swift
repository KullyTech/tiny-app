//
//  LibraryView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 02/11/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var searchText: String = ""
    @State private var path: [LibraryModel] = []
    private let libraries = LibraryModel.dummyData

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(libraries) { library in
                        FolderCardView(library: library) {
                            path.append(library) // 👈 trigger navigation
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Library")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: LibraryModel.self) { library in
                LibraryDetailView(library: library)
            }
        }
    }
}

#Preview {
    LibraryView()
}
