import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class BrandManager {
    static let shared = BrandManager()
    private init() {}
    
    private let brandCollection = Firestore.firestore().collection("brands")
    
    func uploadBrand(_ brand: Brand) async throws {
        try brandCollection.document(brand.name.lowercased()).setData(from: brand, merge: true)
    }

    func getBrandByName(_ name: String) async throws -> Brand? {
        let snapshot = try await brandCollection
            .whereField("name", isEqualTo: name)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first?.data(as: Brand.self)
    }

    func getAllBrands() async throws -> [Brand] {
        let snapshot = try await brandCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Brand.self) }
    }
}
