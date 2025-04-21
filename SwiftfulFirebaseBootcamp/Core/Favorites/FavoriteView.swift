import SwiftUI

struct FavoriteView: View {
    @StateObject private var viewModel = FavoriteViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var cartProductIds: Set<Int> = []
    @State private var favoriteProductIds: Set<Int> = []
    @State private var cartAddedProductId: Int? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.favoriteProducts) { product in
                        OverlayProductCardView(
                            product: product,
                            isFavorited: true,
                            isCartAdded: cartAddedProductId == product.id,
                            onTap: {
                                selectedProduct = product
                            },
                            onToggleFavorite: {
                                if let match = viewModel.userFavoriteProducts.first(where: { $0.productId == product.id }) {
                                    viewModel.removeFromFavorites(favoriteProductId: match.id)
                                }
                            },
                            onAddToCart: {
                                Task {
                                    if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
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
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Favorites")
            .onAppear {
                viewModel.addListenerForFavorites()
                viewModel.loadFavoriteProductIds()
                Task {
                    cartProductIds = await viewModel.loadCartProductIds()
                    favoriteProductIds = viewModel.favoriteProductIds
                }
            }
            .sheet(item: $selectedProduct) { product in
                SingleProductView(product: product)
            }
        }
    }
}

// ✅ Move this to Product.swift or wherever Product is declared
