import SwiftUI
import Kingfisher

struct ProductFiltersView: View {
    @ObservedObject var viewModel: ProductsViewModel

    var body: some View {
        VStack(spacing: 14) {
            // 🆕 New Arrivals Toggle
            Toggle(isOn: $viewModel.showNewArrivalsOnly) {
                Label("Pouze novinky", systemImage: "sparkles")
                    .font(.subheadline.bold())
            }
            .toggleStyle(SwitchToggleStyle(tint: .black))
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)

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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                    ForEach(viewModel.availableSizes, id: \.self) { size in
                        let isSelected = viewModel.selectedSizes.contains(size)
                        Button(action: {
                            viewModel.selectedSizes.toggleItem(size)
                            viewModel.applyFilters()
                        }) {
                            Text(size)
                                .font(.subheadline)
                                .frame(width: 50, height: 36)
                                .background(isSelected ? Color.black : Color.gray.opacity(0.2))
                                .foregroundColor(isSelected ? .white : .black)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(isSelected ? 1 : 0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 🏷 Brand Filter
            FilterSection(title: "Značka") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 10) {
                    ForEach(viewModel.availableBrands, id: \.self) { brand in
                        let isSelected = viewModel.selectedBrands.contains(brand)
                        let logoUrl = viewModel.loadedBrandMap[brand]?.logoUrl

                        BrandChipView(
                            brandName: brand,
                            logoUrl: logoUrl,
                            isSelected: isSelected
                        ) {
                            viewModel.selectedBrands.toggleItem(brand)
                            viewModel.applyFilters()
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 💰 Price Range Filter
            FilterSection(title: "Cena") {
                VStack(alignment: .leading, spacing: 12) {
                    if let range = viewModel.selectedPriceRange {
                        HStack {
                            Text("Od: \(range.lowerBound) CZK")
                            Spacer()
                            Text("Do: \(range.upperBound) CZK")
                        }
                        .font(.caption)
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

                    Button("Od nejlevnějšího") {
                        Task {
                            try? await viewModel.filterSelected(option: .lowestFirst)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal)

            content
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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

struct BrandChipView: View {
    let brandName: String
    let logoUrl: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let logoUrl = logoUrl, let url = URL(string: logoUrl) {
                    KFImage(url)
                        .resizable()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.2)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                }

                Text(brandName)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .black)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.black : Color.gray.opacity(0.2))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(isSelected ? 1 : 0.3), lineWidth: 1)
            )
        }
    }
}
