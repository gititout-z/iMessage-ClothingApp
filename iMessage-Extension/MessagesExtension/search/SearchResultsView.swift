// MARK: - SearchResultsView.swift
import SwiftUI

struct SearchResultsView: View {
    let query: String
    
    @State private var results: [ClothingMatch] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter: String?
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    private let filters = ["All", "Tops", "Bottoms", "Dresses", "Shoes", "Accessories"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters, id: \.self) { filter in
                        FilterChip(
                            title: filter,
                            isSelected: selectedFilter == filter || (filter == "All" && selectedFilter == nil)
                        ) {
                            if filter == "All" {
                                selectedFilter = nil
                            } else {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Results
            if isLoading {
                LoadingIndicator(isLoading: true, text: "Searching...")
            } else if let error = errorMessage {
                ErrorView(errorMessage: error) {
                    performSearch()
                }
            } else if filteredResults.isEmpty {
                emptyResultsView
            } else {
                resultsListView
            }
        }
        .padding(EdgeInsets(
            top: messageSafeArea.top,
            leading: messageSafeArea.left,
            bottom: messageSafeArea.bottom,
            trailing: messageSafeArea.right
        ))
        .onAppear {
            performSearch()
        }
    }
    
    private var filteredResults: [ClothingMatch] {
        if let filter = selectedFilter {
            return results.filter { $0.item.metadata.category == filter }
        } else {
            return results
        }
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredResults) { match in
                    ClothingMatchRow(match: match)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .refreshable {
            performSearch()
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.headline)
            
            Text("Try changing your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func performSearch() {
        isLoading = true
        errorMessage = nil
        
        let searchService = SearchService.shared
        
        searchService.searchByText(query: query) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let matches):
                    self.results = matches
                case .failure(let error):
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .accentColor : .primary)
                .cornerRadius(16)
        }
    }
}
