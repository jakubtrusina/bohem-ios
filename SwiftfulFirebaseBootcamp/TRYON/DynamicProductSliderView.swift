import SwiftUI

struct DynamicProductSlider: View {
    let sliderId: String

    @StateObject private var sliderVM = ProductSliderViewModel()
    @ObservedObject private var vm = ProductsViewModel.shared

    @State private var cartAddedProductIds: Set<String> = []
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false
    @State private var hasTrackedSliderView = false

    var body: some View {
        VStack(spacing: 16) {
            if let config = sliderVM.config {
                if sliderVM.products.isEmpty {
                    Text("⚠️ Žádné produkty k zobrazení")
                        .foregroundColor(.red)
                        .padding(.top, 8)
                } else {
                    // Ensure event is tracked only once

                    // MARK: - Product ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(sliderVM.products) { product in
                                SliderProductCardView(
                                    product: product,
                                    isFavorited: vm.favoriteProductIds.contains(product.id),
                                    isCartAdded: cartAddedProductIds.contains(product.id),
                                    onTap: {
                                        selectedProduct = product
                                        isShowingDetail = true
                                        AnalyticsManager.shared.logProductView(product: product)
                                    },
                                    onToggleFavorite: {
                                        Task {
                                            let updated = await vm.toggleFavoriteProduct(
                                                productId: product.id,
                                                currentFavorites: vm.favoriteProductIds
                                            )
                                            await MainActor.run {
                                                vm.favoriteProductIds = updated
                                            }

                                            let isNowFavorited = updated.contains(product.id)
                                            AnalyticsManager.shared.logEvent(.addToFavorites, params: [
                                                "item_id": product.id,
                                                "favorited": isNowFavorited.description,
                                                "title": product.title ?? "",
                                                "category": product.category ?? "",
                                                "brand": product.brand ?? ""
                                            ])
                                        }
                                    },
                                    onAddToCart: {
                                        Task {
                                            guard let size = product.sizes?.first?.size else {
                                                print("❌ No available size for product \(product.title ?? product.id)")
                                                return
                                            }
                                            await CartManager.shared.addToCart(product: product, size: size, quantity: 1)
                                            withAnimation {
                                                cartAddedProductIds.insert(product.id)
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                cartAddedProductIds.remove(product.id)
                                            }

                                            AnalyticsManager.shared.logAddToCart(product: product, quantity: 1)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                ProgressView("Načítání produktů...")
            }
        }

        // MARK: - Initial Fetch
        .task {
            if let preloaded = SliderPrefetcher.shared.getConfig(for: sliderId) {
                await sliderVM.fetchProductsFromPrefetchedConfig(preloaded)
            } else {
                await sliderVM.fetchConfig(sliderId: sliderId)
            }
        }

        // MARK: - Respond to sliderId Change
        .onChange(of: sliderId) { newValue in
            hasTrackedSliderView = false
            Task {
                if let preloaded = SliderPrefetcher.shared.getConfig(for: newValue) {
                    await sliderVM.fetchProductsFromPrefetchedConfig(preloaded)
                } else {
                    await sliderVM.fetchConfig(sliderId: newValue)
                }
            }
        }

        // MARK: - Detail Sheet
        .sheet(item: $selectedProduct) { product in
            SingleProductView(productId: product.id)
        }
        .task {
            if let config = sliderVM.config, !hasTrackedSliderView {
                AnalyticsManager.shared.logCustomEvent(name: "slider_viewed", params: [
                    "slider_id": sliderId,
                    "slider_title": config.title
                ])
                hasTrackedSliderView = true
            }
        }
    }
}
