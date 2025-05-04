import SwiftUI

struct ProductSliderView: View {
    @StateObject private var viewModel = ProductsViewModel.shared
    @State private var favoriteProductIds: Set<String> = []
    @State private var cartAddedProductId: String? = nil
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false

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
        VStack(spacing: 4) {
            // Main Category Selector
            TryOnMainCategorySelector(
                categories: mainCategories,
                selectedCategory: $viewModel.selectedMainCategory,
                onSelect: { category in
                    withAnimation(.easeInOut) {
                        viewModel.selectedMainCategory = category
                        viewModel.selectedSubcategory = nil
                        viewModel.getProducts()
                        viewModel.filterProducts(for: nil)
                    }
                    AnalyticsManager.shared.logCategorySelected(main: category, sub: nil)
                }
            )

            // Subcategory Selector
            if let subList = subcategories[viewModel.selectedMainCategory] {
                TryOnSubcategorySelector(
                    subcategories: subList,
                    selectedSubcategory: viewModel.selectedSubcategory ?? "Vše",
                    onSelect: { sub in
                        withAnimation(.easeInOut) {
                            let subValue = sub == "Vše" ? nil : sub
                            viewModel.selectedSubcategory = subValue
                            viewModel.filterProducts(for: subValue)
                        }
                        AnalyticsManager.shared.logCategorySelected(
                            main: viewModel.selectedMainCategory,
                            sub: sub == "Vše" ? nil : sub
                        )
                    }
                )
            }

            // Product ScrollView
            if viewModel.filteredProducts.isEmpty {
                Text("Již brzy")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ProductSliderScrollView(
                    products: viewModel.filteredProducts,
                    favoriteProductIds: favoriteProductIds,
                    cartAddedProductId: cartAddedProductId,
                    onTap: { product in
                        selectedProduct = product
                        // Prevents empty sheet on first load
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isShowingDetail = true
                        }
                    },
                    onToggleFavorite: { product in
                        Task {
                            let updated = await viewModel.toggleFavoriteProduct(
                                productId: product.id,
                                currentFavorites: favoriteProductIds
                            )
                            favoriteProductIds = updated
                            if updated.contains(product.id) {
                                AnalyticsManager.shared.logAddToFavorites(product: product)
                            }
                        }
                    },
                    onAddToCart: { product in
                        Task {
                            await CartManager.shared.addToCart(product: product, size: "M", quantity: 1)
                            AnalyticsManager.shared.logAddToCart(product: product, quantity: 1)
                            withAnimation {
                                cartAddedProductId = product.id
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                cartAddedProductId = nil
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": "ProductSliderView"])
            viewModel.getProducts()
            viewModel.loadFavoriteProductIds()
            favoriteProductIds = viewModel.favoriteProductIds
        }
        .sheet(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(productId: product.id)
            } else {
                ProgressView().padding()
            }
        }
    }
}
