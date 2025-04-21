//
//  FavoriteViewModel.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Nick Sarno on 1/22/23.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FavoriteViewModel: ObservableObject {
    
    @Published private(set) var userFavoriteProducts: [UserFavoriteProduct] = []
    @Published var favoriteProducts: [Product] = []
    @Published var favoriteProductIds: Set<Int> = []

    private var cancellables = Set<AnyCancellable>()

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
    
    func loadFavoriteProductIds() {
        self.favoriteProductIds = Set(userFavoriteProducts.map { $0.productId })
    }

    func toggleCartProduct(product: Product, currentCartIds: Set<Int>) async -> Set<Int> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return currentCartIds }
        var updated = currentCartIds

        if updated.contains(product.id) {
            try? await UserManager.shared.removeUserCartProduct(userId: authDataResult.uid, productId: product.id)
            updated.remove(product.id)
        } else {
            try? await UserManager.shared.addUserCartProduct(userId: authDataResult.uid, product: product)
            updated.insert(product.id)
        }

        return updated
    }

    func toggleFavoriteProduct(productId: Int, currentFavorites: Set<Int>) async -> Set<Int> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return currentFavorites }
        var updated = currentFavorites

        if updated.contains(productId) {
            try? await UserManager.shared.removeUserFavoriteProductByProductId(userId: authDataResult.uid, productId: productId)
            updated.remove(productId)
        } else {
            try? await UserManager.shared.addUserFavoriteProduct(userId: authDataResult.uid, productId: productId)
            updated.insert(productId)
        }

        return updated
    }

    func loadCartProductIds() async -> Set<Int> {
        guard let authDataResult = try? AuthenticationManager.shared.getAuthenticatedUser() else { return [] }
        let cartProducts = try? await UserManager.shared.getAllUserCartProducts(userId: authDataResult.uid)
        return Set(cartProducts?.map { $0.id } ?? [])
    }

    private func loadProducts(favorites: [UserFavoriteProduct]) async {
        var loaded: [Product] = []

        for favorite in favorites {
            if let product = try? await ProductsManager.shared.getProduct(productId: String(favorite.productId)) {
                loaded.append(product)
            }
        }

        await MainActor.run {
            self.favoriteProducts = loaded
            self.favoriteProductIds = Set(favorites.map { $0.productId })
        }
    }

    func removeFromFavorites(favoriteProductId: String) {
        Task {
            let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
            try? await UserManager.shared.removeUserFavoriteProduct(userId: authDataResult.uid, favoriteProductId: favoriteProductId)
        }
    }
}
