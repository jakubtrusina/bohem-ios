import FirebaseFirestoreSwift

struct CartItem: Identifiable, Codable, Hashable {
    var id: String { "\(product.id)-\(size.size)" }
    let product: Product
    var size: ProductSize  // ✅ MUST BE 'var', not 'let'
    var quantity: Int

    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CartItem {
    var dictionary: [String: Any] {
        return [
            "productId": product.id,
            "size": size.size,
            "quantity": quantity
        ]
    }
}
