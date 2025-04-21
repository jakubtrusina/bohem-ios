import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
final class ProductsViewModel: ObservableObject {
    @Published private(set) var allProducts: [Product] = []
    @Published private(set) var filteredProducts: [Product] = []
    @Published private(set) var favoriteProductIds: Set<Int> = []

    @Published var selectedMainCategory: String = "Dámské Oblečení"
    @Published var selectedSubcategory: String? = nil

    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedCategory: CategoryOption? = nil
    private var lastDocument: DocumentSnapshot? = nil

    enum FilterOption: String, CaseIterable {
        case noFilter
        case priceHigh
        case priceLow

        var priceDescending: Bool? {
            switch self {
            case .noFilter: return nil
            case .priceHigh: return true
            case .priceLow: return false
            }
        }
    }

    func filterSelected(option: FilterOption) async throws {
        self.selectedFilter = option
        self.allProducts = []
        self.filteredProducts = []
        self.lastDocument = nil
        self.getProducts()
    }

    func loadFavoriteProductIds() {
        Task {
            let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
            let favorites = try await UserManager.shared.getAllUserFavoriteProducts(userId: authUser.uid)
            self.favoriteProductIds = Set(favorites.map { $0.productId })
        }
    }

    enum CategoryOption: String, CaseIterable {
        case noCategory
        case smartphones
        case laptops
        case fragrances

        var categoryKey: String? {
            self == .noCategory ? nil : self.rawValue
        }
    }

    func categorySelected(option: CategoryOption) async throws {
        self.selectedCategory = option
        self.allProducts = []
        self.filteredProducts = []
        self.lastDocument = nil
        self.getProducts()
    }

    func getProducts() {
        Task {
            let (newProducts, lastDocument) = try await ProductsManager.shared.getAllProducts(
                priceDescending: selectedFilter?.priceDescending,
                forCategory: selectedCategory?.categoryKey,
                count: 30,
                lastDocument: lastDocument
            )

            self.allProducts.append(contentsOf: newProducts)
            self.lastDocument = lastDocument
            self.filterProducts(for: selectedSubcategory) // Initial filter
        }
    }

    // MARK: - New Local Filter for Horizontal UI
    func filterProducts(for subcategory: String?) {
        self.selectedSubcategory = subcategory

        if let sub = subcategory, !sub.isEmpty {
            self.filteredProducts = allProducts.filter {
                $0.category?.localizedCaseInsensitiveContains(sub) == true
            }
        } else {
            self.filteredProducts = allProducts
        }
    }

    // MARK: - Cart & Favorites
    func toggleCartProduct(product: Product, currentCartIds: Set<Int>) async -> Set<Int> {
        var updated = currentCartIds
        do {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            if updated.contains(product.id) {
                try await UserManager.shared.removeUserCartProduct(userId: user.uid, productId: product.id)
                updated.remove(product.id)
            } else {
                try await UserManager.shared.addUserCartProduct(userId: user.uid, product: product)
                updated.insert(product.id)
            }
        } catch {
            print("❌ Cart toggle failed:", error)
        }
        return updated
    }

    func addToCart(product: Product, size: String, quantity: Int) async {
        do {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            
            let cartItem = CartItem(
                id: String(product.id),
                product: product,
                size: size,
                quantity: quantity
            )
            
            try Firestore.firestore()
                .collection("users")
                .document(user.uid)
                .collection("cart_products")
                .document(String(product.id))
                .setData(from: cartItem)
        } catch {
            print("❌ Failed to add to cart with size/quantity:", error)
        }
    }


    func toggleFavoriteProduct(productId: Int, currentFavorites: Set<Int>) async -> Set<Int> {
        var updated = currentFavorites
        do {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            if updated.contains(productId) {
                try await UserManager.shared.removeUserFavoriteProductByProductId(userId: user.uid, productId: productId)
                updated.remove(productId)
            } else {
                try await UserManager.shared.addUserFavoriteProduct(userId: user.uid, productId: productId)
                updated.insert(productId)
            }
        } catch {
            print("❌ Favorite toggle failed:", error)
        }
        return updated
    }

    func addUserFavoriteProduct(productId: Int) {
        Task {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            try await UserManager.shared.addUserFavoriteProduct(userId: user.uid, productId: productId)
            favoriteProductIds.insert(productId)
        }
    }

    func removeUserFavoriteProduct(productId: Int) {
        Task {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            try await UserManager.shared.removeUserFavoriteProductByProductId(userId: user.uid, productId: productId)
        }
    }

    func loadCartProductIds() async -> Set<Int> {
        do {
            let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
            let products = try await UserManager.shared.getAllUserCartProducts(userId: authUser.uid)
            return Set(products.map { $0.id })
        } catch {
            print("❌ Failed to load cart products:", error)
            return []
        }
    }
}
