// MARK: - SocialView.swift
import SwiftUI

struct SocialView: View {
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var suggestedUsers: [User] = []
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    private let tabs = ["Following", "Followers", "Discover"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tabs
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tabs[index])
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                                    .foregroundColor(selectedTab == index ? .accentColor : .primary)
                                
                                Rectangle()
                                    .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
                
                // Search bar for all tabs
                SearchBar(text: $searchText, placeholder: "Find people...") {
                    // Handle search
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if isLoading {
                    LoadingIndicator(isLoading: true, text: "Loading...")
                } else if let error = errorMessage {
                    ErrorView(errorMessage: error) {
                        loadData()
                    }
                } else {
                    // Tab content
                    TabView(selection: $selectedTab) {
                        // Following
                        followingView
                            .tag(0)
                        
                        // Followers
                        followersView
                            .tag(1)
                        
                        // Discover
                        discoverView
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .padding(EdgeInsets(
                top: messageSafeArea.top,
                leading: messageSafeArea.left,
                bottom: messageSafeArea.bottom,
                trailing: messageSafeArea.right
            ))
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadData()
        }
    }

    private var followingView: some View {
        VStack {
            if filteredFollowing.isEmpty {
                emptyStateView(message: "You're not following anyone yet", buttonText: "Discover People")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFollowing) { user in
                            UserRow(user: user, isFollowing: true)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .refreshable {
                    loadData()
                }
            }
        }
    }

    private var followersView: some View {
        VStack {
            if filteredFollowers.isEmpty {
                emptyStateView(message: "You don't have any followers yet", buttonText: "Share Your Profile")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredFollowers) { user in
                            UserRow(user: user, isFollowing: following.contains { $0.id == user.id })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .refreshable {
                    loadData()
                }
            }
        }
    }

    private var discoverView: some View {
        VStack {
            if filteredSuggestions.isEmpty {
                emptyStateView(message: "No suggestions available", buttonText: "Try Again")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSuggestions) { user in
                            UserRow(user: user, isFollowing: following.contains { $0.id == user.id })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .refreshable {
                    loadData()
                }
            }
        }
    }

    private func emptyStateView(message: String, buttonText: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
            
            Button(action: {
                if buttonText == "Discover People" {
                    selectedTab = 2 // Switch to Discover tab
                } else if buttonText == "Try Again" {
                    loadData()
                }
            }) {
                Text(buttonText)
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

    private var filteredFollowing: [User] {
        if searchText.isEmpty { return following }
        return following.filter { user in
            user.username.localizedCaseInsensitiveContains(searchText) ||
            user.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredFollowers: [User] {
        if searchText.isEmpty { return followers }
        return followers.filter { user in
            user.username.localizedCaseInsensitiveContains(searchText) ||
            user.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredSuggestions: [User] {
        if searchText.isEmpty { return suggestedUsers }
        return suggestedUsers.filter { user in
            user.username.localizedCaseInsensitiveContains(searchText) ||
            user.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        let socialManager = SocialManager.shared
        
        // Load followers
        socialManager.getFollowers { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.followers = users
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load followers: \(error.localizedDescription)"
                }
            }
        }
        
        // Load following
        socialManager.getFollowing { result in
            switch result {
            case .success(let users):
                DispatchQueue.main.async {
                    self.following = users
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load following: \(error.localizedDescription)"
                }
            }
        }
        
        // Load suggested users
        socialManager.getSuggestedUsers { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let users):
                    self.suggestedUsers = users
                case .failure(let error):
                    if self.errorMessage == nil {
                        self.errorMessage = "Failed to load suggestions: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}