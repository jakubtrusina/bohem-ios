//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/1/25.
//

import SwiftUI

struct ProductFiltersView: View {
    @ObservedObject var viewModel: ProductsViewModel

    @State private var availableColors: [String] = []
    @State private var availableSizes: [String] = []
    @State private var availableBrands: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 🆕 New Arrivals Toggle
            Toggle(isOn: $viewModel.showNewArrivalsOnly) {
                Label("Show New Arrivals", systemImage: "sparkles")
            }
            .toggleStyle(SwitchToggleStyle(tint: .black))

            // 🎨 Colors
            if !availableColors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by Color").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.") { color in
                                Button(action: {
                                    if viewModel.selectedColors.contains(color) {
                                        viewModel.selectedColors.removeAll { $0 == color }
                                    } else {
                                        viewModel.selectedColors.append(color)
                                    }
                                }) {
                                    Text(color)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedColors.contains(color) ? Color.black : Color.gray.opacity(0.2))
                                        .foregroundColor(viewModel.selectedColors.contains(color) ? .white : .black)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }

            // 🔢 Sizes
            if !availableSizes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by Size").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableSizes, id: \.") { size in
                                Button(action: {
                                    if viewModel.selectedSizes.contains(size) {
                                        viewModel.selectedSizes.removeAll { $0 == size }
                                    } else {
                                        viewModel.selectedSizes.append(size)
                                    }
                                }) {
                                    Text(size)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedSizes.contains(size) ? Color.black : Color.gray.opacity(0.2))
                                        .foregroundColor(viewModel.selectedSizes.contains(size) ? .white : .black)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }

            // 💰 Price Range
            VStack(alignment: .leading) {
                Text("Price Range").font(.headline)
                if let range = viewModel.selectedPriceRange {
                    Text("\(range.lowerBound) CZK – \(range.upperBound) CZK")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                RangeSlider(range: Binding(
                    get: { viewModel.selectedPriceRange ?? 0...10000 },
                    set: { viewModel.selectedPriceRange = $0 }
                ), in: 0...10000, step: 100)
                    .accentColor(.black)
            }

            // 🏷 Brands
            if !availableBrands.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Filter by Brand").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableBrands, id: \.") { brand in
                                Button(action: {
                                    if viewModel.selectedBrands.contains(brand) {
                                        viewModel.selectedBrands.removeAll { $0 == brand }
                                    } else {
                                        viewModel.selectedBrands.append(brand)
                                    }
                                }) {
                                    Text(brand)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedBrands.contains(brand) ? Color.black : Color.gray.opacity(0.2))
                                        .foregroundColor(viewModel.selectedBrands.contains(brand) ? .white : .black)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }

            // 🔁 Apply Button
            Button(action: {
                viewModel.applyFilters()
            }) {
                HStack {
                    Spacer()
                    Text("Apply Filters")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                }
                .background(Color.black)
                .cornerRadius(12)
            }
        }
        .padding()
        .onAppear {
            // ⚙️ Extract all unique values
            let all = viewModel.allProducts
            availableColors = Array(Set(all.flatMap { $0.colors ?? [] })).sorted()
            availableSizes = Array(Set(all.flatMap { $0.sizes?.map { $0.size } ?? [] })).sorted()
            availableBrands = Array(Set(all.compactMap { $0.brand })).sorted()
        }
    }
}

// Reusable RangeSlider (for SwiftUI < iOS 17 compatibility)
struct RangeSlider: View {
    @Binding var range: ClosedRange<Int>
    let inRange: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(spacing: 4) {
            Slider(value: Binding(
                get: { Double(range.lowerBound) },
                set: { range = Int($0)...range.upperBound }
            ), in: Double(inRange.lowerBound)...Double(inRange.upperBound), step: Double(step))
            Slider(value: Binding(
                get: { Double(range.upperBound) },
                set: { range = range.lowerBound...Int($0) }
            ), in: Double(inRange.lowerBound)...Double(inRange.upperBound), step: Double(step))
        }
    }
}
