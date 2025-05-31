import SwiftUI

struct FavoriteView: View {
    @StateObject private var viewModel = FavoriteViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var cartProductIds: Set<String> = []
    @ObservedObject private var vm = ProductsViewModel.shared
    @State private var cartAddedProductId: String? = nil
    @Environment(\.dismiss) var dismiss

    @Binding var bannerTarget: BannerNavigationTarget?
    @Binding var showMenu: Bool
    @Binding var showSignInView: Bool

    var body: some View {
        VStack {
            if viewModel.favoriteProducts.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("Zatím nemáte žádné oblíbené produkty.")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("Prozkoumejte naši kolekci a přidejte si produkty, které se vám líbí.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        bannerTarget = .category("Dámské Oblečení")
                    } label: {
                        Text("Přejít na produkty")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.favoriteProducts) { product in
                            OverlayProductCardView(
                                product: product,
                                isFavorited: vm.favoriteProductIds.contains(product.id),
                                isCartAdded: isCartAdded(product),
                                onTap: { handleTap(product) },
                                onToggleFavorite: { handleToggleFavorite(product) },
                                onAddToCart: { handleAddToCart(product) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.addListenerForFavorites()
            Task {
                cartProductIds = await viewModel.loadCartProductIds()
            }
        }
        .onDisappear {
            selectedProduct = nil
            cartProductIds = []
            cartAddedProductId = nil
        }
        .sheet(item: $selectedProduct) { product in
            SingleProductView(productId: product.id)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    private func isCartAdded(_ product: Product) -> Bool {
        return cartAddedProductId == product.id
    }

    private func handleTap(_ product: Product) {
        selectedProduct = product
    }

    private func handleToggleFavorite(_ product: Product) {
        Task {
            let updated = await vm.toggleFavoriteProduct(productId: product.id, currentFavorites: vm.favoriteProductIds)
            await MainActor.run {
                vm.favoriteProductIds = updated
            }

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
