// MARK: - MessageSafeArea.swift
import SwiftUI
import Messages

struct MessageSafeArea: View {
    let content: AnyView
    
    @Environment(\.messageSafeArea) var messageSafeArea
    
    init<Content: View>(_ content: Content) {
        self.content = AnyView(content)
    }
    
    var body: some View {
        content
            .padding(EdgeInsets(
                top: messageSafeArea.top,
                leading: messageSafeArea.left,
                bottom: messageSafeArea.bottom,
                trailing: messageSafeArea.right
            ))
    }
}