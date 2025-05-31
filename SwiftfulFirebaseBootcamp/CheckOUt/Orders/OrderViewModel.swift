//
//  OrderViewModel.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []

    func fetchOrders() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("orders")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching orders:", error)
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.orders = documents.compactMap { try? $0.data(as: Order.self) }
            }
    }
}
