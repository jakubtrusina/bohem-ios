import Foundation
import FirebaseFirestore

final class BrandManager {
    static let shared = BrandManager()
    private init() {}

    private let brandCollection = Firestore.firestore().collection("brands")

    func uploadBrand(_ brand: Brand) async throws {
        try brandCollection
            .document(brand.name.lowercased())
            .setData(from: brand, merge: true)
    }

    func getBrandByName(_ name: String) async throws -> Brand {
        let snapshot = try await Firestore.firestore()
            .collection("brands")
            .whereField("name", isEqualTo: name)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw NSError(domain: "BrandManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Brand not found with name: \(name)"])
        }

        do {
            let brand = try document.data(as: Brand.self)
            return brand
        } catch {
            print("❌ Failed to decode brand: \(document.data())")
            throw error
        }
    }


    func getAllBrands() async throws -> [Brand] {
        let snapshot = try await brandCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Brand.self) }
    }
}
