import SwiftUI

struct ProductFiltersView: View {
    @ObservedObject var viewModel: ProductsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 🆕 New Arrivals Toggle
                Toggle("Pouze novinky", isOn: $viewModel.showNewArrivalsOnly)
                    .toggleStyle(SwitchToggleStyle(tint: .black))
                    .padding(.horizontal)
                    .onChange(of: viewModel.showNewArrivalsOnly) { _ in
                        viewModel.applyFilters()
                    }

                // 🎨 Color Filter
                FilterSection(title: "Barva") {
                    ColorWrapHStack(
                        selectedItems: $viewModel.selectedColors,
                        allItems: viewModel.availableColors
                    ) { color in
                        viewModel.selectedColors.toggleItem(color)
                        viewModel.applyFilters()
                    }
                }

                // 📏 Size Filter
                FilterSection(title: "Velikost") {
                    WrapHStack(
                        selectedItems: $viewModel.selectedSizes,
                        allItems: viewModel.availableSizes
                    ) { size in
                        viewModel.selectedSizes.toggleItem(size)
                        viewModel.applyFilters()
                    }
                }

                // 🏷 Brand Filter
                FilterSection(title: "Značka") {
                    WrapHStack(
                        selectedItems: $viewModel.selectedBrands,
                        allItems: viewModel.availableBrands
                    ) { brand in
                        viewModel.selectedBrands.toggleItem(brand)
                        viewModel.applyFilters()
                    }
                }

                // 💰 Price Range Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cena")
                        .font(.headline)
                        .padding(.horizontal)

                    if let range = viewModel.selectedPriceRange {
                        Text("\(range.lowerBound) CZK – \(range.upperBound) CZK")
                            .font(.subheadline)
                            .padding(.horizontal)
                    }

                    Slider(
                        value: Binding(
                            get: {
                                Double(viewModel.selectedPriceRange?.upperBound ?? Int(viewModel.maxProductPrice))
                            },
                            set: { newUpper in
                                viewModel.selectedPriceRange = Int(viewModel.minProductPrice)...Int(newUpper)
                                viewModel.applyFilters()
                            }
                        ),
                        in: viewModel.minProductPrice...viewModel.maxProductPrice,
                        step: 100
                    )
                    .accentColor(.black)
                    .padding(.horizontal)
                }

                // 🔄 Reset Button
                Button("Resetovat filtry") {
                    viewModel.resetFilters()
                }
                .foregroundColor(.red)
                .padding(.top)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Filter Section Wrapper
struct FilterSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            content
        }
    }
}

// MARK: - WrapHStack (Text-based options)
struct WrapHStack: View {
    @Binding var selectedItems: [String]
    let allItems: [String]
    let onToggle: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
            ForEach(allItems, id: \.self) { item in
                Button(action: {
                    onToggle(item)
                }) {
                    Text(item)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedItems.contains(item) ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(selectedItems.contains(item) ? .white : .black)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(selectedItems.contains(item) ? 1 : 0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - ColorWrapHStack (Color-based chips)
struct ColorWrapHStack: View {
    @Binding var selectedItems: [String]
    let allItems: [String]
    let onToggle: (String) -> Void

    private func colorForName(_ name: String) -> Color {
        switch name.lowercased() {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "pink": return .pink
        case "gray": return .gray
        case "brown": return .brown
        default: return .secondary
        }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
            ForEach(allItems, id: \.self) { item in
                Button(action: {
                    onToggle(item)
                }) {
                    Circle()
                        .fill(colorForName(item))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(selectedItems.contains(item) ? Color.black : Color.clear, lineWidth: 2)
                        )
                        .overlay(
                            selectedItems.contains(item) ? Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(.white) : nil
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Array Toggle Helper
extension Array where Element == String {
    mutating func toggleItem(_ item: String) {
        if contains(item) {
            removeAll { $0 == item }
        } else {
            append(item)
        }
    }
}
