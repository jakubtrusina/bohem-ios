//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReturnsViewModel: ObservableObject {
    @Published var returns: [Return] = []

    func fetchReturns() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("returns")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching returns:", error)
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.returns = documents.compactMap { try? $0.data(as: Return.self) }
            }
    }
}
