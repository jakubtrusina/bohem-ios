//
//  TryOnCategorySelectorView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/15/25.
//

import SwiftUI

/// Horizontal category tab used in Try-On product slider
struct TryOnMainCategorySelector: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == category ? .bold : .regular)
                            .foregroundColor(selectedCategory == category ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == category
                                ? Color.white
                                : Color.white.opacity(0.2)
                            )
                            .cornerRadius(18)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Horizontal subcategory tab used in Try-On product slider
struct TryOnSubcategorySelector: View {
    let subcategories: [String]
    let selectedSubcategory: String?
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(subcategories, id: \.self) { sub in
                    Button {
                        onSelect(sub)
                    } label: {
                        Text(sub)
                            .font(.footnote)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedSubcategory == sub
                                ? Color.white.opacity(0.9)
                                : Color.white.opacity(0.2)
                            )
                            .foregroundColor(selectedSubcategory == sub ? .black : .white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
