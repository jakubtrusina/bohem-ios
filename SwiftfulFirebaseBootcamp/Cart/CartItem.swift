import FirebaseFirestore

struct CartItem: Identifiable, Codable, Hashable {
    let id: String // <- Keep it persistent (not regenerated)
    let product: Product
    var size: ProductSize
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
