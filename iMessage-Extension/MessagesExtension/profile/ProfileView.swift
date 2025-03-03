// MARK: - ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var clothingItems: [ClothingItem] = []
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    @State private var showEditProfile = false
    @State private var errorMessage: String?
    @State private var refreshTrigger = false
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    // Categories for filtering
    private let categories = ["All", "Tops", "Bottoms", "Outerwear", "Dresses", "Shoes", "Accessories"]
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    LoadingIndicator(isLoading: isLoading, text: "Loading Profile")
                } else if let error = errorMessage {
                    ErrorView(errorMessage: error) {
                        loadProfile()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Profile header with user info
                            if let user = authService.currentUser {
                                ProfileHeader(user: user, isCurrentUser: true)
                                    .padding(.bottom)
                            }
                            
                            // Category filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        CategoryButton(
                                            title: category,
                                            isSelected: selectedCategory == category || (category == "All" && selectedCategory == nil)
                                        ) {
                                            if category == "All" {
                                                selectedCategory = nil
                                            } else {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            
                            // Clothing grid
                            if filteredItems.isEmpty {
                                emptyStateView
                            } else {
                                ClothingGridView(items: filteredItems) { item in
                                    // Handle item selection
                                    print("Selected item: \(item.id)")
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .refreshable {
                        loadProfile()
                    }
                }
            }
            .padding(EdgeInsets(
                top: messageSafeArea.top,
                leading: messageSafeArea.left,
                bottom: messageSafeArea.bottom,
                trailing: messageSafeArea.right
            ))
            .navigationTitle("My Closet")
            .navigationBarItems(
                trailing: Button(action: {
                    showEditProfile = true
                }) {
                    Text("Edit")
                }
            )
            .sheet(isPresented: $showEditProfile) {
                if let user = authService.currentUser {
                    EditProfileView(user: user) { updatedUser in
                        // Update local user data
                        // This would trigger a UI refresh
                        refreshTrigger.toggle()
                    }
                }
            }
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private var filteredItems: [ClothingItem] {
        if let category = selectedCategory {
            return clothingItems.filter { $0.metadata.category == category }
        } else {
            return clothingItems
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(selectedCategory == nil ? "Your closet is empty" : "No items in this category")
                .font(.headline)
            
            Text("Add clothing items using the camera tab")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Switch to the camera tab
                // This would be handled by the parent tab controller
            }) {
                Text("Add Clothing")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        // In a real app, fetch the user's items from CloudKit
        if let userId = authService.currentUser?.id {
            let clothingService = ClothingService.shared
            
            clothingService.getItemsForUser(userId: userId) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    switch result {
                    case .success(let items):
                        self.clothingItems = items
                    case .failure(let error):
                        self.errorMessage = "Failed to load items: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            isLoading = false
            errorMessage = "User not found. Please sign in again."
        }
    }
}

struct CategoryButton: View {
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