import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

@MainActor
final class CartManager: ObservableObject {
    static let shared = CartManager()
    private let db = Firestore.firestore()
    
    @Published var cartItems: [CartItem] = []

    func loadCartItems() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("cart_products")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self?.cartItems = documents.compactMap { try? $0.data(as: CartItem.self) }
            }
    }

    func addToCart(product: Product, size: String, quantity: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if let productSize = product.sizes?.first(where: { $0.size == size }) {
            let item = CartItem(product: product, size: productSize, quantity: quantity)
            let docId = "\(product.id)-\(productSize.size)"

            do {
                try db.collection("users")
                    .document(uid)
                    .collection("cart_products")
                    .document(docId)
                    .setData(from: item)
                await loadCartItems()
            } catch {
                print("❌ Error adding to cart:", error)
            }
        }
    }

    func updateQuantity(docId: String, quantity: Int) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(docId)
                .updateData(["quantity": quantity])

            let updatedItems = try await UserManager.shared.getAllUserCartProducts(userId: uid)
            DispatchQueue.main.async {
                self.cartItems = self.cartItems.map { current in
                    if current.id == docId {
                        var updated = current
                        updated.quantity = quantity
                        return updated
                    } else {
                        return current
                    }
                }
            }
        } catch {
            print("❌ Error updating quantity:", error)
        }
    }

    func updateSize(item: CartItem, newSize: ProductSize) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let oldDocId = "\(item.product.id)-\(item.size.size)"
        let newDocId = "\(item.product.id)-\(newSize.size)"

        do {
            try await db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(oldDocId)
                .delete()

            var updatedItem = item
            updatedItem.size = newSize

            try await db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(newDocId)
                .setData(updatedItem.dictionary)

            let updatedItems = try await UserManager.shared.getAllUserCartProducts(userId: uid)
            DispatchQueue.main.async {
                self.cartItems = updatedItems
            }

        } catch {
            print("❌ Error updating size:", error)
        }
    }

    func remove(productId: String, size: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let docId = "\(productId)-\(size)"

        do {
            try await db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(docId)
                .delete()
        } catch {
            print("❌ Error removing product:", error)
        }
    }

    func clearCart() {
        cartItems.removeAll()
    }
}
