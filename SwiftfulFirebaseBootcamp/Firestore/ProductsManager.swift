import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ProductsManager {
    
    static let shared = ProductsManager()
    private init() { }

    private let productsCollection = Firestore.firestore().collection("products")

    private func productDocument(productId: String) -> DocumentReference {
        productsCollection.document(productId)
    }

    func getProduct(productId: String) async throws -> Product {
        try await productDocument(productId: productId).getDocument(as: Product.self)
    }

    func uploadProduct(product: Product) async throws {
        try await product.withValidID { id in
            try productDocument(productId: id).setData(from: product, merge: false)
        }
    }

    func getProductsForIds(ids: [String]) async throws -> [Product] {
        guard !ids.isEmpty else { return [] }

        var products: [Product] = []
        let chunkedIds = ids.chunked(into: 10)

        for chunk in chunkedIds {
            let snapshot = try await productsCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let chunkProducts = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
            products.append(contentsOf: chunkProducts)
        }

        return products
    }

    // MARK: - Firestore Query Helpers (normalized field based)

    private func getAllProductsQuery() -> Query {
        productsCollection
    }

    private func getAllProductsSortedByPriceQuery(descending: Bool) -> Query {
        productsCollection.order(by: Product.CodingKeys.price.rawValue, descending: descending)
    }

    private func getAllProductsForCategoryQuery(category: String) -> Query {
        productsCollection.whereField("category_normalized", isEqualTo: category)
    }

    private func getAllProductsByPriceAndCategoryQuery(descending: Bool, category: String) -> Query {
        productsCollection
            .whereField("category_normalized", isEqualTo: category)
            .order(by: Product.CodingKeys.price.rawValue, descending: descending)
    }

    // MARK: - Main Public Product Fetcher

    func getAllProducts(
        priceDescending descending: Bool?,
        forCategory category: String?,
        count: Int,
        lastDocument: DocumentSnapshot?
    ) async throws -> (products: [Product], lastDocument: DocumentSnapshot?) {
        var query: Query = getAllProductsQuery()

        if let descending, let category {
            query = getAllProductsByPriceAndCategoryQuery(descending: descending, category: category)
        } else if let descending {
            query = getAllProductsSortedByPriceQuery(descending: descending)
        } else if let category {
            query = getAllProductsForCategoryQuery(category: category)
        }

        return try await query
            .startOptionally(afterDocument: lastDocument)
            .limit(to: count)
            .getDocumentsWithSnapshot(as: Product.self)
    }

    // MARK: - Additional Queries

    func getProductsByRating(count: Int, lastDocument: DocumentSnapshot?) async throws -> (products: [Product], lastDocument: DocumentSnapshot?) {
        let query = productsCollection
            .order(by: Product.CodingKeys.rating.rawValue, descending: true)
            .limit(to: count)

        if let lastDocument {
            return try await query
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as: Product.self)
        } else {
            return try await query.getDocumentsWithSnapshot(as: Product.self)
        }
    }

    func getAllProductsCount() async throws -> Int {
        try await productsCollection.aggregateCount()
    }

    func getProductsByBrand(brandName: String) async -> [Product] {
        do {
            let snapshot = try await productsCollection
                .whereField("brand", isEqualTo: brandName)
                .getDocuments()

            return snapshot.documents.compactMap { try? $0.data(as: Product.self) }
        } catch {
            print("❌ Error fetching brand products:", error)
            return []
        }
    }
}

// MARK: - Helper
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
