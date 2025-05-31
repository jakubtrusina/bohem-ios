import SwiftUI

struct ProductSliderView: View {
    var showFilters: Bool = true
    var filteredProducts: [Product]? = nil

    @ObservedObject private var vm = ProductsViewModel.shared
    @State private var cartAddedProductIds: Set<String> = []
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false

    let mainCategories: [String] = [
        "Dámské Oblečení",
        "Dámské Plavky",
        "Doplňky"
    ]

    let subcategories: [String: [String]] = [
        "Dámské Oblečení": ["Šaty", "Dámská Trička", "Kabát", "Kalhoty", "Mikiny", "Sukně"],
        "Dámské Plavky": ["Jednodílné", "Horní díl", "Spodní díl"],
        "Doplňky": ["Náhrdelníky", "Náramky", "Náušnice", "Pásky", "Prstýnky", "Tašky"]
    ]

    var body: some View {
        VStack(spacing: 4) {
            if showFilters {
                TryOnMainCategorySelector(
                    categories: mainCategories,
                    selectedCategory: $vm.selectedMainCategory,
                    onSelect: { category in
                        withAnimation(.easeInOut) {
                            vm.selectedMainCategory = category
                            vm.selectedSubcategory = nil
                            vm.getProducts()
                            vm.filterProducts(for: nil)
                        }
                        AnalyticsManager.shared.logCategorySelected(main: category, sub: nil)
                    }
                )

                if let subList = subcategories[vm.selectedMainCategory] {
                    TryOnSubcategorySelector(
                        subcategories: subList,
                        selectedSubcategory: vm.selectedSubcategory ?? "Vše",
                        onSelect: { sub in
                            withAnimation(.easeInOut) {
                                let subValue = sub == "Vše" ? nil : sub
                                vm.selectedSubcategory = subValue
                                vm.filterProducts(for: subValue)
                            }
                            AnalyticsManager.shared.logCategorySelected(
                                main: vm.selectedMainCategory,
                                sub: sub == "Vše" ? nil : sub
                            )
                        }
                    )
                }
            }

            let productsToShow = filteredProducts ?? vm.filteredProducts

            if productsToShow.isEmpty {
                Text("Již brzy")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ProductSliderScrollView(
                    products: productsToShow,
                    favoriteProductIds: vm.favoriteProductIds,
                    cartAddedProductIds: cartAddedProductIds,
                    onTap: { product in
                        selectedProduct = product
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isShowingDetail = true
                        }
                    },
                    onToggleFavorite: { product in
                        Task {
                            let updated = await vm.toggleFavoriteProduct(
                                productId: product.id,
                                currentFavorites: vm.favoriteProductIds
                            )
                            if updated.contains(product.id) {
                                AnalyticsManager.shared.logAddToFavorites(product: product)
                            }
                        }
                    },
                    onAddToCart: { product in
                        Task {
                            guard let size = product.sizes?.first?.size else {
                                print("❌ No available size for product \(product.title ?? product.id)")
                                return
                            }

                            await CartManager.shared.addToCart(product: product, size: size, quantity: 1)
                            AnalyticsManager.shared.logAddToCart(product: product, quantity: 1)
                            withAnimation {
                                cartAddedProductIds.insert(product.id)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                cartAddedProductIds.remove(product.id)
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": "ProductSliderView"])
            vm.getProducts()
            vm.loadFavoriteProductIds()
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
