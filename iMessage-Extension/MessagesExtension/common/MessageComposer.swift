// MARK: - MessageComposer.swift
import Foundation
import Messages
import UIKit

class MessageComposer {
    static let shared = MessageComposer()
    
    private init() {}
    
    // Create a message with a clothing item
    func composeMessage(with item: ClothingItem, in conversation: MSConversation) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        // Set message properties
        message.summaryText = "Check out this clothing item"
        
        // Create layout
        layout.image = createPreviewImage(for: item)
        layout.imageTitle = item.metadata.description
        layout.imageSubtitle = item.metadata.category
        layout.caption = "via Clothing App"
        
        // Set the message layout
        message.layout = layout
        
        // Build URL with deep link to the item
        var components = URLComponents()
        components.path = "/item"
        components.queryItems = [
            URLQueryItem(name: "id", value: item.id)
        ]
        
        if let url = components.url {
            message.url = url
        }
        
        return message
    }
    
    // Create a message with search results
    func composeSearchMessage(query: String, in conversation: MSConversation) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        // Set message properties
        message.summaryText = "Clothing search results"
        
        // Create layout
        layout.image = UIImage(systemName: "magnifyingglass")
        layout.imageTitle = "Search: \(query)"
        layout.imageSubtitle = "Tap to view results"
        layout.caption = "via Clothing App"
        
        // Set the message layout
        message.layout = layout
        
        // Build URL with deep link to the search
        var components = URLComponents()
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        if let url = components.url {
            message.url = url
        }
        
        return message
    }
    
    // Create a message with a user profile
    func composeProfileMessage(user: User, in conversation: MSConversation) -> MSMessage {
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        
        // Set message properties
        message.summaryText = "User profile: @\(user.username)"
        
        // Create layout
        if let avatarURL = user.avatarURL {
            // In a real app, load the image from the URL
            layout.image = UIImage(systemName: "person.crop.circle")
        } else {
            layout.image = UIImage(systemName: "person.crop.circle")
        }
        
        layout.imageTitle = user.displayName
        layout.imageSubtitle = "@\(user.username)"
        layout.caption = "via Clothing App"
        
        // Set the message layout
        message.layout = layout
        
        // Build URL with deep link to the profile
        var components = URLComponents()
        components.path = "/profile"
        components.queryItems = [
            URLQueryItem(name: "id", value: user.id)
        ]
        
        if let url = components.url {
            message.url = url
        }
        
        return message
    }
    
    // Send a message
    func sendMessage(_ message: MSMessage, in conversation: MSConversation) {
        conversation.insert(message) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper function to create a preview image
    private func createPreviewImage(for item: ClothingItem) -> UIImage? {
        // In a real app, this would download and process the item's image
        // For now, return a placeholder
        return UIImage(systemName: "tshirt.fill")
    }
}