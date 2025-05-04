//
//  WomenCategorySelectorView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/11/25.
//

import SwiftUI

struct WomenCategorySelectorView: View {
    @ObservedObject var viewModel: ProductsViewModel

    let mainCategories: [String] = [
        "Dámské Oblečení",
        "Dámské Plavky",
        "Doplňky"
    ]

    let subcategories: [String: [String]] = [
        "Dámské Oblečení": [
            "Šaty",
            "Dámská Trička",
            "Kabát",        // Treated as standalone subcategory now
            "Kalhoty",
            "Mikiny",
            "Sukně"
        ],
        "Dámské Plavky": [
            "Jednodílné",
            "Horní díl",
            "Spodní díl"
        ],
        "Doplňky": [
            "Náhrdelníky",
            "Náramky",
            "Náušnice",
            "Pásky",
            "Prstýnky",
            "Tašky"
        ]
    ]


    var body: some View {
        VStack(alignment: .leading) {
            // Main categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(mainCategories, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedMainCategory = category
                            viewModel.getProducts()
                        }) {
                            Text(category)
                                .fontWeight(viewModel.selectedMainCategory == category ? .bold : .regular)
                                .foregroundColor(viewModel.selectedMainCategory == category ? .black : .gray)
                                .underline(viewModel.selectedMainCategory == category, color: .black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            Divider().padding(.bottom, 4)

            // Subcategories
            if let subs = subcategories[viewModel.selectedMainCategory] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subs, id: \.self) { sub in
                            Button(action: {
                                viewModel.filterProducts(for: sub == "Vše" ? nil : sub)
                            }) {
                                Text(sub)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedSubcategory == sub ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(viewModel.selectedSubcategory == sub ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
    }
}
