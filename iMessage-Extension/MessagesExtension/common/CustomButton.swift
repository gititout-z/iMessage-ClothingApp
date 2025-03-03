// MARK: - CustomButton.swift
import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var backgroundColor: Color = .accentColor
    var foregroundColor: Color = .white
    var height: CGFloat = 50
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var icon: String? = nil
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .padding(.trailing, 5)
                }
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .opacity(isDisabled ? 0.7 : 1.0)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .opacity(isDisabled ? 0.7 : 1.0)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isDisabled ? backgroundColor.opacity(0.6) : backgroundColor)
            .cornerRadius(10)
        }
        .disabled(isDisabled || isLoading)
    }
}