import Foundation
import SwiftUI
import Combine

@MainActor
final class FavoriteViewModel: ObservableObject {

    @Published private(set) var userFavoriteProducts: [UserFavoriteProduct] = []
    @Published var favoriteProducts: [Product] = []
    @Published var favoriteProductIds: Set<String> = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Firebase Listeners

    func addListenerForFavorites() {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return }

        UserManager.shared.addListenerForAllUserFavoriteProducts(userId: authDataResult.uid)
            .sink { _ in } receiveValue: { [weak self] favorites in
                self?.userFavoriteProducts = favorites
                Task {
                    await self?.loadProducts(favorites: favorites)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Load IDs

    func loadFavoriteProductIds() {
        self.favoriteProductIds = Set(userFavoriteProducts.map { $0.productId })
    }

    func loadCartProductIds() async -> Set<String> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return [] }
        let cartProducts = try? await UserManager.shared.getAllUserCartProducts(userId: authDataResult.uid)
        return Set(cartProducts?.compactMap { $0.id } ?? [])
    }

    // MARK: - Toggle Cart Product

    func toggleCartProduct(product: Product, currentCartIds: Set<String>) async -> Set<String> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return currentCartIds }
        var updated = currentCartIds

        await product.withValidID { id in
            if updated.contains(id) {
                try? await UserManager.shared.removeUserCartProduct(userId: authDataResult.uid, productId: id)
                updated.remove(id)
            } else {
                try? await UserManager.shared.addUserCartProduct(userId: authDataResult.uid, product: product, size: "M", quantity: 1)
                updated.insert(id)
            }
        }

        return updated
    }

    // MARK: - Toggle Favorite Product

    func toggleFavoriteProduct(productId: String, currentFavorites: Set<String>) async -> Set<String> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return currentFavorites }
        var updated = currentFavorites

        if updated.contains(productId) {
            try? await UserManager.shared.removeUserFavoriteProductByProductId(userId: authDataResult.uid, productId: productId)
            updated.remove(productId)
        } else {
            try? await UserManager.shared.addUserFavoriteProduct(userId: authDataResult.uid, productId: productId)
            updated.insert(productId)
        }

        await MainActor.run {
            self.favoriteProductIds = updated
            ProductsViewModel.shared.favoriteProductIds = updated  // 🔁 App-wide sync here
        }

        return updated
    }


    // MARK: - Optimized Remove Favorite (INSTANT UI)

    func removeFromFavorites(favoriteProductId: String) {
        Task {
            guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return }

            // ✅ Optimistic UI update
            await MainActor.run {
                self.userFavoriteProducts.removeAll { $0.id == favoriteProductId }
                self.favoriteProducts.removeAll { $0.id == favoriteProductId }
                self.favoriteProductIds.remove(favoriteProductId)
            }

            // 🔄 Async Firestore update
            try? await UserManager.shared.removeUserFavoriteProduct(userId: authDataResult.uid, favoriteProductId: favoriteProductId)
        }
    }

    // MARK: - Private Helpers

    private func loadProducts(favorites: [UserFavoriteProduct]) async {
        var loaded: [Product] = []

        for favorite in favorites {
            if let product = try? await ProductsManager.shared.getProduct(productId: favorite.productId) {
                loaded.append(product)
            }
        }

        await MainActor.run {
            self.favoriteProducts = loaded
            self.favoriteProductIds = Set(favorites.map { $0.productId })
        }
    }
}

