import Foundation
import FirebaseFirestore
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
            let item = CartItem(
                id: UUID().uuidString, // 🔐 new persistent ID
                product: product,
                size: productSize,
                quantity: quantity
            )

            let docId = item.id // 🔁 document ID is now stable

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

            DispatchQueue.main.async {
                if let index = self.cartItems.firstIndex(where: { $0.id == docId }) {
                    self.cartItems[index].quantity = quantity
                }
            }

        } catch {
            print("❌ Error updating quantity:", error)
        }
    }

    func updateSize(item: CartItem, newSize: ProductSize) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let docId = item.id // ✅ not based on size anymore

        do {
            var updatedItem = item
            updatedItem.size = newSize

            try await db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(docId)
                .setData(from: updatedItem) // ✅ full overwrite

            DispatchQueue.main.async {
                if let index = self.cartItems.firstIndex(where: { $0.id == item.id }) {
                    self.cartItems[index] = updatedItem
                }
            }

        } catch {
            print("❌ Error updating size:", error)
        }
    }



    func remove(docId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

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
