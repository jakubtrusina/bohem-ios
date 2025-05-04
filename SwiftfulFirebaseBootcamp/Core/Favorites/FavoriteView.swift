import SwiftUI

struct FavoriteView: View {
    @StateObject private var viewModel = FavoriteViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var cartProductIds: Set<String> = []
    @State private var favoriteProductIds: Set<String> = []
    @State private var cartAddedProductId: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.favoriteProducts) { product in
                        OverlayProductCardView(
                            product: product,
                            isFavorited: true,
                            isCartAdded: isCartAdded(product),
                            onTap: { handleTap(product) },
                            onToggleFavorite: { handleToggleFavorite(product) },
                            onAddToCart: { handleAddToCart(product) }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("menu_favorites")
            .onAppear {
                viewModel.addListenerForFavorites()
                viewModel.loadFavoriteProductIds()
                Task {
                    cartProductIds = await viewModel.loadCartProductIds()
                    favoriteProductIds = viewModel.favoriteProductIds
                }
            }
            .sheet(item: $selectedProduct) { product in
                SingleProductView(productId: product.id)
            }
        }
    }

    // MARK: - Extracted Handlers

    private func isCartAdded(_ product: Product) -> Bool {
        return cartAddedProductId == product.id
    }

    private func handleTap(_ product: Product) {
        selectedProduct = product
    }

    private func handleToggleFavorite(_ product: Product) {
        if let match = viewModel.userFavoriteProducts.first(where: { $0.productId == product.id }) {
            viewModel.removeFromFavorites(favoriteProductId: match.id)
        }
    }

    private func handleAddToCart(_ product: Product) {
        Task {
            if let _ = try? AuthenticationManager.shared.getAuthenticatedUser() {
                await CartManager.shared.addToCart(product: product, size: "M", quantity: 1)
                withAnimation {
                    cartAddedProductId = product.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    cartAddedProductId = nil
                }
            }
        }
    }
}
