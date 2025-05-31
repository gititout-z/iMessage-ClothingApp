// MARK: - FilterOptions.swift
import SwiftUI

struct FilterOptions: View {
    @Binding var selectedCategory: String?
    @Binding var selectedPriceRange: ClosedRange<Double>
    @Binding var selectedColors: Set<String>
    @Binding var selectedBrands: Set<String>
    
    let categories = ["Tops", "Bottoms", "Dresses", "Outerwear", "Shoes", "Accessories"]
    let colors = ["Black", "White", "Red", "Blue", "Green", "Yellow", "Purple", "Pink", "Brown", "Gray"]
    let brands = ["Nike", "Adidas", "H&M", "Zara", "Levi's", "Gap", "Ralph Lauren", "Calvin Klein", "Forever 21", "Gucci"]
    
    let priceRange: ClosedRange<Double> = 0...500
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                CategoriesSection(selectedCategory: $selectedCategory, categories: categories)
                PriceRangeSectionView(selectedPriceRange: $selectedPriceRange) // Renamed to avoid conflict
                ColorsSection(selectedColors: $selectedColors, colors: colors)
                BrandsSection(selectedBrands: $selectedBrands, brands: brands)
                ClearFiltersSection(
                    selectedCategory: $selectedCategory,
                    selectedPriceRange: $selectedPriceRange,
                    selectedColors: $selectedColors,
                    selectedBrands: $selectedBrands,
                    priceRange: priceRange
                )
            }
            .navigationTitle("Filter Options")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Subviews for FilterOptions
private struct CategoriesSection: View {
    @Binding var selectedCategory: String?
    let categories: [String]

    var body: some View {
        Section(header: Text("Categories")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        FilterChip( // Assuming FilterChip is defined elsewhere or is simple enough
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            if selectedCategory == category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct PriceRangeSectionView: View { // Renamed to avoid potential conflict
    @Binding var selectedPriceRange: ClosedRange<Double>

    var body: some View {
        Section(header: Text("Price Range")) {
            Text("$\(Int(selectedPriceRange.lowerBound)) - $\(Int(selectedPriceRange.upperBound))")
                .font(.subheadline)

            // Placeholder for slider
            HStack {
                Text("$0")
                Spacer()
                Text("$500")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

private struct ColorsSection: View {
    @Binding var selectedColors: Set<String>
    let colors: [String]

    var body: some View {
        Section(header: Text("Colors")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors, id: \.self) { color in
                        ColorFilterChip( // This struct is already defined below
                            colorName: color,
                            isSelected: selectedColors.contains(color)
                        ) {
                            if selectedColors.contains(color) {
                                selectedColors.remove(color)
                            } else {
                                selectedColors.insert(color)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct BrandsSection: View {
    @Binding var selectedBrands: Set<String>
    let brands: [String]

    var body: some View {
        Section(header: Text("Brands")) {
            ForEach(brands, id: \.self) { brand in
                Button(action: {
                    if selectedBrands.contains(brand) {
                        selectedBrands.remove(brand)
                    } else {
                        selectedBrands.insert(brand)
                    }
                }) {
                    HStack {
                        Text(brand)
                        Spacer()
                        if selectedBrands.contains(brand) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(.primary) // Keep text color consistent
            }
        }
    }
}

private struct ClearFiltersSection: View {
    @Binding var selectedCategory: String?
    @Binding var selectedPriceRange: ClosedRange<Double>
    @Binding var selectedColors: Set<String>
    @Binding var selectedBrands: Set<String>
    let priceRange: ClosedRange<Double> // Original full range

    var body: some View {
        Section {
            Button(action: {
                selectedCategory = nil
                selectedPriceRange = priceRange
                selectedColors.removeAll()
                selectedBrands.removeAll()
            }) {
                Text("Clear All Filters")
                    .foregroundColor(.red)
            }
        }
    }
}

struct ColorFilterChip: View { // This struct was already present
    let colorName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(colorFromName(colorName))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                
                Text(colorName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
        }
    }
    
    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return Color(red: 0.6, green: 0.4, blue: 0.2)
        case "gray": return .gray
        default: return .primary
        }
    }
}