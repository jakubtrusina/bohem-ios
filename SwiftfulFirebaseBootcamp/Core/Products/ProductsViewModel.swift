import Foundation
import SwiftUI
import FirebaseFirestore

extension String {
    var normalized: String {
        self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class ProductsViewModel: ObservableObject {
    static let shared = ProductsViewModel()

    // MARK: - Published State
    @Published private(set) var allProducts: [Product] = []
    @Published private(set) var filteredProducts: [Product] = []
    @Published var favoriteProductIds: Set<String> = []
    @Published var selectedColors: [String] = []
    @Published var selectedSizes: [String] = []
    @Published var selectedPriceRange: ClosedRange<Int>? = nil
    @Published var selectedBrands: [String] = []
    @Published var showNewArrivalsOnly: Bool = false
    @Published var loadedBrandMap: [String: Brand] = [:]
    @Published var selectedMainCategory: String = "Dámské Oblečení"
    @Published var selectedSubcategory: String? = nil
    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedCategory: CategoryOption? = nil

    private(set) var lastDocument: DocumentSnapshot?
    private var productsListener: ListenerRegistration?

    var minProductPrice: Double {
        Double(allProducts.compactMap { $0.price }.min() ?? 500)
    }

    var maxProductPrice: Double {
        Double(allProducts.compactMap { $0.price }.max() ?? 6000)
    }

    var availableColors: [String] {
        Array(Set(allProducts.flatMap { $0.colors ?? [] })).sorted()
    }

    var availableSizes: [String] {
        Array(Set(allProducts.flatMap { $0.sizes?.map { $0.size } ?? [] })).sorted()
    }

    var availableBrands: [String] {
        Array(Set(allProducts.compactMap { $0.brand })).sorted()
    }

    func resetFilters() {
        selectedColors = []
        selectedSizes = []
        selectedPriceRange = nil
        selectedBrands = []
        showNewArrivalsOnly = false
        applyFilters()
    }

    func loadBrands() {
        Task {
            do {
                let brands = try await BrandManager.shared.getAllBrands()
                DispatchQueue.main.async {
                    self.loadedBrandMap = Dictionary(uniqueKeysWithValues: brands.map { ($0.name, $0) })
                }
            } catch {
                print("❌ Failed to load brands: \(error.localizedDescription)")
            }
        }
    }

    
    // MARK: - Enums
    enum FilterOption: String, CaseIterable {
        case noFilter
        case lowestFirst
        case highestFirst

        var priceDescending: Bool? {
            switch self {
            case .noFilter: return nil
            case .highestFirst: return true
            case .lowestFirst: return false
            }
        }

        var displayName: String {
            switch self {
            case .noFilter: return "Bez řazení"
            case .lowestFirst: return "Od nejlevnějšího"
            case .highestFirst: return "Od nejdražšího"
            }
        }
    }
    enum CategoryOption: String, CaseIterable {
        case noCategory, smartphones, laptops, fragrances

        var categoryKey: String? {
            self == .noCategory ? nil : self.rawValue
        }
    }
    
    func getProducts(forBrand brandName: String) {
        productsListener?.remove()

        let query = Firestore.firestore().collection("products")
            .whereField("brand", isEqualTo: brandName)

        productsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Firestore error:", error.localizedDescription)
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ No snapshot")
                return
            }

            let decoded = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
            self.allProducts = decoded
            self.filteredProducts = decoded
            print("✅ Loaded \(decoded.count) products for brand \(brandName)")
        }
    }



    // MARK: - Core Methods
    func clearFilters() {
        selectedFilter = nil
        selectedSubcategory = nil
        allProducts = []
        filteredProducts = []
        lastDocument = nil
        getProducts()
    }

    func inferMainCategory(for subcategory: String, from available: [String: [String]]) -> String? {
        for (main, subs) in available {
            if subs.contains(subcategory) {
                return main
            }
        }
        return nil
    }

    
    func getProducts() {
        productsListener?.remove()

        // 🚨 Prevent calling Firestore with an empty category
        guard !selectedMainCategory.isEmpty else {
            print("❌ Cannot fetch products: selectedMainCategory is empty")
            return
        }

        let normalizedCategory = selectedMainCategory.normalized
        print("🟡 Setting up listener for category_normalized = '\(normalizedCategory)'")

        var query: Query = Firestore.firestore().collection("products")
            .whereField("category_normalized", isEqualTo: normalizedCategory)

        if let descending = selectedFilter?.priceDescending {
            query = query.order(by: "price", descending: descending)
        }

        productsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            print("📡 Firestore snapshot triggered")

            if let error = error {
                print("❌ Firestore listener error:", error.localizedDescription)
                return
            }

            guard let snapshot = snapshot else {
                print("⚠️ No snapshot received")
                return
            }

            print("📦 Snapshot contains \(snapshot.documents.count) documents")

            let decoded = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
            decoded.forEach { print("✅ Decoded product: \($0.title ?? "Untitled")") }

            self.allProducts = decoded
            self.applyFilters()
        }
    }


    func products(forBrand brandName: String) async -> [Product] {
        return allProducts.filter { $0.brand == brandName }
    }

    func applyFilters() {
        filteredProducts = allProducts.filter { product in
            var match = true

            if let sub = selectedSubcategory?.normalized, !sub.isEmpty, sub != "vše" {
                match = match && (product.subcategory?.normalized == sub)
            }

            if !selectedSizes.isEmpty {
                match = match && (product.sizes?.contains { selectedSizes.contains($0.size) } ?? false)
            }

            if !selectedColors.isEmpty {
                match = match && (product.colors?.contains(where: selectedColors.contains) ?? false)
            }

            if let range = selectedPriceRange, let price = product.price {
                match = match && range.contains(price)
            }

            if !selectedBrands.isEmpty {
                match = match && (product.brand.map { selectedBrands.contains($0) } ?? false)
            }

            if showNewArrivalsOnly {
                match = match && (product.isNewArrival == true)
            }

            return match
        }

        print("✅ Final filtered products count: \(filteredProducts.count)")
    }

    func filterProducts(for subcategory: String?) {
        selectedSubcategory = subcategory
        applyFilters()
    }

    func filterSelected(option: FilterOption) async throws {
        selectedFilter = option
        allProducts = []
        filteredProducts = []
        lastDocument = nil
        getProducts()
    }

    func categorySelected(option: CategoryOption) async throws {
        selectedCategory = option
        allProducts = []
        filteredProducts = []
        lastDocument = nil
        getProducts()
    }

    func downloadProductsAndUploadToFirebase() {
        guard let url = Bundle.main.url(forResource: "products", withExtension: "json") else {
            print("❌ Failed to locate products.json in bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let products = try JSONDecoder().decode([Product].self, from: data)
            print("✅ Loaded \(products.count) products.")

            Task {
                var uploaded = 0
                for product in products {
                    do {
                        try await uploadProductToFirestore(product)
                        uploaded += 1
                    } catch {
                        print("❌ Upload failed for \(product.title ?? "Unknown"):", error)
                    }
                }
                print("✅ Uploaded \(uploaded)/\(products.count) products to Firestore")
            }
        } catch {
            print("❌ Error decoding local products.json:", error)
        }
    }

    private func uploadProductToFirestore(_ product: Product) async throws {
        let db = Firestore.firestore()
        try await product.withValidID { id in
            var productWithId = product
            productWithId.id = id

            let normalizedSub = product.subcategory?.normalized
            let normalizedCat = product.category?.normalized

            var data = try Firestore.Encoder().encode(productWithId)
            data["subcategory_normalized"] = normalizedSub
            data["category_normalized"] = normalizedCat

            try await db.collection("products").document(id).setData(data)
        }
    }

    func loadFavoriteProductIds() {
        Task {
            let authUser = try await AuthenticationManager.shared.getAuthenticatedUser()
            let favorites = try await UserManager.shared.getAllUserFavoriteProducts(userId: authUser.uid)
            favoriteProductIds = Set(favorites.map { $0.productId })
        }
    }

    func toggleCartProduct(product: Product, size: String, currentCartIds: Set<String>) async -> Set<String> {
        var updated = currentCartIds
        let docId = "\(product.id)-\(size)"

        do {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            if updated.contains(docId) {
                try await UserManager.shared.removeUserCartProduct(userId: user.uid, productId: docId)
                updated.remove(docId)
            } else {
                try await UserManager.shared.addUserCartProduct(userId: user.uid, product: product, size: size, quantity: 1)
                updated.insert(docId)
            }
        } catch {
            print("❌ Cart toggle failed:", error)
        }

        return updated
    }

    func toggleFavoriteProduct(productId: String, currentFavorites: Set<String>) async -> Set<String> {
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

            // 🔄 Update the Published property to sync UI
            await MainActor.run {
                self.favoriteProductIds = updated
            }

        } catch {
            print("❌ Favorite toggle failed:", error)
        }

        return updated
    }

    func addUserFavoriteProduct(productId: String) {
        Task {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            try await UserManager.shared.addUserFavoriteProduct(userId: user.uid, productId: productId)
            favoriteProductIds.insert(productId)
        }
    }

    func removeUserFavoriteProduct(productId: String) {
        Task {
            let user = try await AuthenticationManager.shared.getAuthenticatedUser()
            try await UserManager.shared.removeUserFavoriteProductByProductId(userId: user.uid, productId: productId)
        }
    }

    func loadCartProductIds() async -> Set<String> {
        do {
            let authUser = try await AuthenticationManager.shared.getAuthenticatedUser()
            let products = try await UserManager.shared.getAllUserCartProducts(userId: authUser.uid)
            return Set(products.compactMap { $0.id })
        } catch {
            print("❌ Failed to load cart products:", error)
            return []
        }
    }

    deinit {
        productsListener?.remove()
    }
}
