// MARK: - ImageSearchResultsView.swift
import SwiftUI

struct ImageSearchResultsView: View {
    let searchImage: UIImage
    
    @State private var socialMatches: [ClothingMatch] = []
    @State private var commercialMatches: [CommercialMatch] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.messageSafeArea) var messageSafeArea
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisplayedSearchImage(searchImage: searchImage) // Extracted View
                    
                    if isLoading {
                        LoadingIndicator(isLoading: true, text: "Finding matches...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let error = errorMessage {
                        ErrorView(errorMessage: error) {
                            performVisualSearch()
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        SocialMatchesSection(socialMatches: socialMatches) // Extracted View
                        CommercialMatchesSection(commercialMatches: commercialMatches) // Extracted View
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(EdgeInsets(
                top: messageSafeArea.top,
                leading: messageSafeArea.left,
                bottom: messageSafeArea.bottom,
                trailing: messageSafeArea.right
            ))
            .navigationTitle("Visual Search Results")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                performVisualSearch()
            }
        }
    }
    
    private func performVisualSearch() {
        isLoading = true
        errorMessage = nil
        
        let searchService = SearchService.shared
        let imageProcessor = ImageProcessor.shared
        
        // Process image to get embedding
        imageProcessor.processImage(searchImage) { result in
            switch result {
            case .success(let embedding):
                // Search with the embedding
                searchService.searchByImage(embedding: embedding) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let (social, commercial)):
                            self.socialMatches = social
                            self.commercialMatches = commercial
                        case .failure(let error):
                            self.errorMessage = "Search failed: \(error.localizedDescription)"
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Image processing failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Subviews for ImageSearchResultsView
private struct DisplayedSearchImage: View {
    let searchImage: UIImage

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image(uiImage: searchImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)

                Text("Search Image")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

private struct SocialMatchesSection: View {
    let socialMatches: [ClothingMatch]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From Your Network")
                .font(.headline)
                .padding(.horizontal)

            if socialMatches.isEmpty {
                Text("No matches found in your network")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(socialMatches) { match in
                            ClothingMatchRow(match: match, isHorizontal: true)
                                .frame(width: 260)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct CommercialMatchesSection: View {
    let commercialMatches: [CommercialMatch]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shop Similar Items")
                .font(.headline)
                .padding(.horizontal)

            if commercialMatches.isEmpty {
                Text("No commercial matches found")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 12) {
                    ForEach(commercialMatches) { match in
                        ClothingPurchaseRow(match: match)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}