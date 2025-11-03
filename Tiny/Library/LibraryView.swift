//
//  LibraryView.swift
//  Tiny
//
//  Created by Destu Cikal Ramdani on 02/11/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var searchText: String = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var path: [LibraryModel] = []
    private let libraries = LibraryModel.dummyData

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case mostRecent = "Most Recent"
        case oldest = "Oldest"
        case mostClips = "Most Clips"
    }

    var filteredLibraries: [LibraryModel] {
        var result = libraries.filter { library in
            searchText.isEmpty || library.name.localizedCaseInsensitiveContains(searchText)
        }

        // Apply sorting based on filter
        switch selectedFilter {
        case .all:
            break // Keep original order
        case .mostRecent:
            result.sort { $0.week > $1.week }
        case .oldest:
            result.sort { $0.week < $1.week }
        case .mostClips:
            result.sort { $0.clipCount > $1.clipCount }
        }

        return result
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                // Search bar and Filter in HStack
                HStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search library", text: $searchText)
                            .textFieldStyle(.plain)

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            })
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Filter button
                    Menu {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                            }, label: {
                                HStack {
                                    Text(option.rawValue)
                                    if selectedFilter == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            })
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Content
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredLibraries) { library in
                            FolderShapeButton(library: library) {
                                path.append(library)
                            }
                        }
                    }
                    .padding()
                }
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
