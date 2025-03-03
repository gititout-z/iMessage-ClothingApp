// MARK: - SearchView.swift
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchMode: SearchMode = .text
    @State private var isSearching = false
    @State private var searchImage: UIImage?
    @State private var showImageSearchResults = false
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    enum SearchMode {
        case text
        case visual
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search modes tabs
                HStack {
                    SearchModeButton(
                        title: "Text",
                        icon: "textformat",
                        isSelected: searchMode == .text
                    ) {
                        searchMode = .text
                    }
                    
                    SearchModeButton(
                        title: "Visual",
                        icon: "camera",
                        isSelected: searchMode == .visual
                    ) {
                        searchMode = .visual
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search input
                SearchBar(text: $searchText, placeholder: "Search clothing...", onSearch: {
                    if searchMode == .text && !searchText.isEmpty {
                        isSearching = true
                    }
                })
                .padding(.horizontal)
                .padding(.vertical, 8)
                .disabled(searchMode == .visual)
                
                // Content based on search mode
                if searchMode == .text {
                    if isSearching && !searchText.isEmpty {
                        SearchResultsView(query: searchText)
                    } else {
                        searchSuggestionsView
                    }
                } else {
                    VisualSearchView(onImageSelected: { image in
                        self.searchImage = image
                        self.showImageSearchResults = true
                    })
                }
            }
            .padding(EdgeInsets(
                top: messageSafeArea.top,
                leading: messageSafeArea.left,
                bottom: messageSafeArea.bottom,
                trailing: messageSafeArea.right
            ))
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImageSearchResults) {
                if let image = searchImage {
                    ImageSearchResultsView(searchImage: image)
                }
            }
        }
    }
    
    private var searchSuggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trending Categories")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Trending categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(trendingCategories, id: \.self) { category in
                            Button(action: {
                                searchText = category
                                isSearching = true
                            }) {
                                VStack {
                                    categoryIcon(for: category)
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 70)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                    
                                    Text(category)
                                        .font(.caption)
                                        .padding(.top, 5)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Text("Recent Searches")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Recent searches
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(recentSearches, id: \.self) { search in
                        Button(action: {
                            searchText = search
                            isSearching = true
                        }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                
                                Text(search)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func categoryIcon(for category: String) -> Image {
        switch category {
        case "Dresses":
            return Image(systemName: "person.crop.rectangle")
        case "Tops":
            return Image(systemName: "tshirt")
        case "Pants":
            return Image(systemName: "scissors")
        case "Shoes":
            return Image(systemName: "bag")
        case "Accessories":
            return Image(systemName: "creditcard")
        default:
            return Image(systemName: "tag")
        }
    }
    
    // Sample data for demo
    private let trendingCategories = ["Dresses", "Tops", "Pants", "Shoes", "Accessories"]
    private let recentSearches = ["blue jeans", "summer dress", "workout top", "denim jacket"]
}

struct SearchModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .animation(.spring(), value: isSelected)
        }
        .frame(maxWidth: .infinity)
    }
}
