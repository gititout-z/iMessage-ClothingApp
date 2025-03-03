// MARK: - SearchBar.swift
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onSearch: () -> Void
    
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text, onCommit: {
                    onSearch()
                })
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button(action: {
                    isEditing = false
                    text = ""
                    
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                }
                .padding(.leading, 8)
                .transition(.move(edge: .trailing))
                .animation(.default, value: isEditing)
            }
        }
        .onTapGesture {
            isEditing = true
        }
    }
}