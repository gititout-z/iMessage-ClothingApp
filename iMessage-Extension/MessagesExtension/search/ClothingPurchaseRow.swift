// MARK: - ClothingPurchaseRow.swift
import SwiftUI

struct ClothingPurchaseRow: View {
    let match: CommercialMatch
    
    var body: some View {
        HStack(spacing: 12) {
            // Product image
            if let imageURL = match.imageURL {
                // In a real app, load from URL
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "tshirt")
                            .foregroundColor(.primary)
                    )
                    .cornerRadius(8)
            }
            
            // Product details
            VStack(alignment: .leading, spacing: 4) {
                Text(match.description)
                    .lineLimit(2)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let brand = match.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(priceFormatted(match.price, currency: match.currency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(match.retailer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Buy button
            Button(action: {
                openPurchaseLink()
            }) {
                Text("Buy")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func priceFormatted(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    private func openPurchaseLink() {
        guard let url = match.purchaseURL else { return }
        
        // Open URL if it's valid
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}