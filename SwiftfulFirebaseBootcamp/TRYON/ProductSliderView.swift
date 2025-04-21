import SwiftUI

struct ProductSliderView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @State private var favoriteProductIds: Set<Int> = []
    @State private var cartAddedProductId: Int? = nil
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false

    private let mainCategories = ["Dámské Oblečení", "Dámské Plavky", "Doplňky"]
    private let subcategories: [String: [String]] = [
        "Dámské Oblečení": ["Vše", "Šaty", "Dámská Trička", "Dámské Kardigany", "Sukně", "Mikiny", "Kalhoty", "Trenčkoty"],
        "Dámské Plavky": ["Vše", "Jednodílné"],
        "Doplňky": ["Vše", "Tašky", "Náhrdelníky", "Náramky", "Náušnice"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            TryOnMainCategorySelector(
                categories: mainCategories,
                selectedCategory: viewModel.selectedMainCategory,
                onSelect: { category in
                    withAnimation {
                        viewModel.selectedMainCategory = category
                        viewModel.selectedSubcategory = nil
                        viewModel.filterProducts(for: nil)
                    }
                    AnalyticsManager.shared.logCategorySelected(main: category, sub: nil)
                }
            )

            if let subList = subcategories[viewModel.selectedMainCategory] {
                TryOnSubcategorySelector(
                    subcategories: subList,
                    selectedSubcategory: viewModel.selectedSubcategory,
                    onSelect: { sub in
                        withAnimation {
                            viewModel.selectedSubcategory = sub
                            viewModel.filterProducts(for: sub == "Vše" ? nil : sub)
                        }
                        AnalyticsManager.shared.logCategorySelected(
                            main: viewModel.selectedMainCategory,
                            sub: sub == "Vše" ? nil : sub
                        )
                    }
                )
            }

            ProductSliderScrollView(
                products: viewModel.filteredProducts,
                favoriteProductIds: favoriteProductIds,
                cartAddedProductId: cartAddedProductId,
                onTap: { product in
                    selectedProduct = product
                    isShowingDetail = true
                    AnalyticsManager.shared.logProductView(product: product)
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
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": "ProductSliderView"])
            viewModel.getProducts()
            viewModel.loadFavoriteProductIds()
            favoriteProductIds = viewModel.favoriteProductIds
        }
        .sheet(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(product: product)
            }
        }
    }
}
