//
//  WomenCategorySelectorView.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/11/25.
//

import SwiftUI

struct WomenCategorySelectorView: View {
    @State private var selectedMain: String = "Dámské Oblečení"
    @State private var selectedSub: String?

    let mainCategories = ["Dámské Oblečení", "Dámské Plavky", "Doplňky"]

    let subcategories: [String: [String]] = [
        "Dámské Oblečení": [
            "Vše", "Šaty", "Dámská Trička", "Dámské Kardigany",
            "Sukně", "Mikiny", "Kalhoty", "Trenčkoty"
        ],
        "Dámské Plavky": [
            "Vše", "Jednodílné"
        ],
        "Doplňky": [
            "Vše", "Tašky", "Náhrdelníky", "Náramky", "Náušnice"
        ]
    ]

    var body: some View {
        VStack(alignment: .leading) {
            // Top category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(mainCategories, id: \.self) { category in
                        Button(action: {
                            selectedMain = category
                            selectedSub = nil
                        }) {
                            Text(category)
                                .fontWeight(selectedMain == category ? .bold : .regular)
                                .foregroundColor(selectedMain == category ? .black : .gray)
                                .underline(selectedMain == category, color: .black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            Divider().padding(.bottom, 4)

            // Subcategories slider
            if let subs = subcategories[selectedMain] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subs, id: \.self) { sub in
                            Button(action: {
                                selectedSub = sub
                                // You can trigger product filtering here
                            }) {
                                Text(sub)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedSub == sub ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedSub == sub ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }

            Spacer()

            // Optional output
            if let selectedSub {
                Text("Selected: \(selectedMain) > \(selectedSub)")
                    .padding()
            }
        }
        .navigationTitle("Categories")
    }
}
