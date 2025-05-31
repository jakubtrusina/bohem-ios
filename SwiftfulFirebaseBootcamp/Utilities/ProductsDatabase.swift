import Foundation
import FirebaseFirestore

struct ProductArray: Codable {
    let products: [Product]
    let total, skip, limit: Int
}

struct ProductSize: Codable, Hashable {
    var size: String
    var stock: Int
}

struct ProductModel: Codable, Hashable {
    let height_cm: Int?
    let wearing_size: String?
}

struct Product: Identifiable, Codable, Equatable, Hashable {
    var id: String
    let title: String?
    let description: [String: String]?
    let price: Int?
    let discountPercentage: Double?
    let rating: Double?
    let stock: Int?
    let brand: String?
    let category: String?
    let subcategory: String?
    let thumbnail: String?
    let images: [String]?
    let sizes: [ProductSize]?
    let alternativeProducts: [String]?
    let similarProducts: [String]?
    let category_normalized: String?
    let subcategory_normalized: String?
    let popularity: Int?
    let isNewArrival: Bool?
    let createdAt: String?
    let material: String?
    let fit: String?
    let colors: [String]?
    let styleTags: [String]?
    let season: [String]?
    let gender: String?
    let care: String?
    let designerNote: String?
    let model: ProductModel?
    let relatedProductIds: [String]?

    init(
        id: String,
        title: String? = nil,
        description: [String: String]? = nil,
        price: Int? = nil,
        discountPercentage: Double? = nil,
        rating: Double? = nil,
        stock: Int? = nil,
        brand: String? = nil,
        category: String? = nil,
        subcategory: String? = nil,
        thumbnail: String? = nil,
        images: [String]? = nil,
        sizes: [ProductSize]? = nil,
        alternativeProducts: [String]? = nil,
        similarProducts: [String]? = nil,
        category_normalized: String? = nil,
        subcategory_normalized: String? = nil,
        popularity: Int? = nil,
        isNewArrival: Bool? = nil,
        createdAt: String? = nil,
        material: String? = nil,
        fit: String? = nil,
        colors: [String]? = nil,
        styleTags: [String]? = nil,
        season: [String]? = nil,
        gender: String? = nil,
        care: String? = nil,
        designerNote: String? = nil,
        model: ProductModel? = nil,
        relatedProductIds: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.brand = brand
        self.category = category
        self.subcategory = subcategory
        self.thumbnail = thumbnail
        self.images = images
        self.sizes = sizes
        self.alternativeProducts = alternativeProducts
        self.similarProducts = similarProducts
        self.category_normalized = category_normalized
        self.subcategory_normalized = subcategory_normalized
        self.popularity = popularity
        self.isNewArrival = isNewArrival
        self.createdAt = createdAt
        self.material = material
        self.fit = fit
        self.colors = colors
        self.styleTags = styleTags
        self.season = season
        self.gender = gender
        self.care = care
        self.designerNote = designerNote
        self.model = model
        self.relatedProductIds = relatedProductIds
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, discountPercentage, rating, stock, brand, category, subcategory, thumbnail, images, sizes, alternativeProducts, similarProducts, category_normalized, subcategory_normalized, popularity, isNewArrival, createdAt, material, fit, colors, styleTags, season, gender, care, designerNote, model, relatedProductIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent([String: String].self, forKey: .description)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        discountPercentage = try container.decodeIfPresent(Double.self, forKey: .discountPercentage)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        stock = try container.decodeIfPresent(Int.self, forKey: .stock)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        category_normalized = try container.decodeIfPresent(String.self, forKey: .category_normalized)
        subcategory_normalized = try container.decodeIfPresent(String.self, forKey: .subcategory_normalized)
        popularity = try container.decodeIfPresent(Int.self, forKey: .popularity)
        isNewArrival = try container.decodeIfPresent(Bool.self, forKey: .isNewArrival)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        fit = try container.decodeIfPresent(String.self, forKey: .fit)
        season = try container.decodeIfPresent([String].self, forKey: .season)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        care = try container.decodeIfPresent(String.self, forKey: .care)
        designerNote = try container.decodeIfPresent(String.self, forKey: .designerNote)
        model = try container.decodeIfPresent(ProductModel.self, forKey: .model)

        images = try Self.decodeJSONStringArray(from: container, key: .images)
        alternativeProducts = try Self.decodeJSONStringArray(from: container, key: .alternativeProducts)
        similarProducts = try Self.decodeJSONStringArray(from: container, key: .similarProducts)
        sizes = try Self.decodeJSONStringObjectArray(from: container, key: .sizes)
        colors = try Self.decodeJSONStringArray(from: container, key: .colors)
        styleTags = try Self.decodeJSONStringArray(from: container, key: .styleTags)
        relatedProductIds = try Self.decodeJSONStringArray(from: container, key: .relatedProductIds)
    }

    static func ==(lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }

    private static func decodeJSONStringArray(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> [String]? {
        if let array = try? container.decodeIfPresent([String].self, forKey: key) {
            return array
        } else if let jsonString = try? container.decodeIfPresent(String.self, forKey: key),
                  let data = jsonString.data(using: .utf8) {
            return try? JSONDecoder().decode([String].self, from: data)
        }
        return nil
    }

    private static func decodeJSONStringObjectArray<T: Decodable>(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> [T]? {
        if let array = try? container.decodeIfPresent([T].self, forKey: key) {
            return array
        } else if let jsonString = try? container.decodeIfPresent(String.self, forKey: key),
                  let data = jsonString.data(using: .utf8) {
            return try? JSONDecoder().decode([T].self, from: data)
        }
        return nil
    }
}

extension Product {
    func withValidID<T>(_ block: (String) throws -> T) rethrows -> T {
        try block(id)
    }

    func withValidID<T>(_ block: (String) async throws -> T) async rethrows -> T {
        try await block(id)
    }

}
