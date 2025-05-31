//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class TryOnHistoryViewModel: ObservableObject {
    @Published var products: [Product] = []

    func fetchTryOnHistory() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let history = data["tryOnHistory"] as? [String] else { return }

            self.fetchProducts(by: history)
        }
    }

    private func fetchProducts(by ids: [String]) {
        let productRef = Firestore.firestore().collection("products")
        let group = DispatchGroup()
        var loaded: [Product] = []

        for id in ids {
            group.enter()
            productRef.document(id).getDocument { doc, _ in
                if let doc = doc, let product = try? doc.data(as: Product.self) {
                    loaded.append(product)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.products = loaded
        }
    }
}
