//
//  ProductSliderViewModel.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Slider Config Model
struct ProductSliderConfig: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var subtitle: String
    var filters: [String: String]  // Supports dynamic keys like category, color, brand...
    var limit: Int
    var sortBy: String
}

// MARK: - ViewModel
@MainActor
class ProductSliderViewModel: ObservableObject {
    @Published var config: ProductSliderConfig?
    @Published var products: [Product] = []
    
    // MARK: - Public Entry Point
    func fetchConfig(sliderId: String) async {
        let db = Firestore.firestore()
        do {
            print("📦 Fetching slider config for ID: \(sliderId)")
            let snapshot = try await db.collection("productSliders").document(sliderId).getDocument()
            if let config = try? snapshot.data(as: ProductSliderConfig.self) {
                self.config = config
                print("✅ Loaded config: \(config.title)")
                await fetchProducts(for: config)
            } else {
                print("⚠️ No config found or decoding failed for sliderId: \(sliderId)")
            }
        } catch {
            print("❌ Error fetching config: \(error)")
        }
    }
    @MainActor
    func fetchProductsFromPrefetchedConfig(_ config: ProductSliderConfig) async {
        self.config = config
        await fetchProducts(for: config)
    }
    
    // MARK: - Private Filtering & Fetching Logic
    @MainActor
    func fetchProducts(for config: ProductSliderConfig) async {
        print("🔎 Fetching products with filters: \(config.filters)")

        let db = Firestore.firestore()
        var query: Query = db.collection("products")

        for (key, value) in config.filters {
            let normalized = value
                .lowercased()
                .folding(options: [.diacriticInsensitive], locale: .current)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            print("🔍 Applying filter – \(key): \(normalized)")

            switch key.lowercased() {
            case "category":
                query = query.whereField("category_normalized", isEqualTo: normalized)
            case "subcategory":
                query = query.whereField("subcategory_normalized", isEqualTo: normalized)
            case "brand":
                query = query.whereField("brand", isEqualTo: value)
            case "color":
                query = query.whereField("colors", arrayContains: value)
            default:
                print("⚠️ Unknown filter key: \(key) – ignoring")
            }
        }

        query = query.order(by: config.sortBy, descending: true)
                     .limit(to: config.limit)

        do {
            let snapshot = try await query.getDocuments()
            self.products = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
            print("✅ Loaded \(products.count) products for slider \(config.title)")
        } catch {
            print("❌ Error fetching products: \(error.localizedDescription)")
        }
    }
}
