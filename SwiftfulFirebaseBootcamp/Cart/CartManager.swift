import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

@MainActor
final class CartManager: ObservableObject {
    static let shared = CartManager()
    private let db = Firestore.firestore()

    @Published private(set) var cartItems: [CartItem] = []

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

        let item = CartItem(product: product, size: size, quantity: quantity)
        let docId = "\(product.id)-\(size)"

        do {
            try db.collection("users")
                .document(uid)
                .collection("cart_products")
                .document(docId)
                .setData(from: item)
        } catch {
            print("❌ Error adding to cart:", error)
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
        } catch {
            print("❌ Error updating quantity:", error)
        }
    }


    func remove(productId: Int, size: String) async {
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

