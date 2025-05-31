//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ClosetViewModel: ObservableObject {
    @Published var closetItems: [ClosetItem] = []

    func fetchCloset() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("closet_products")
            .order(by: "addedDate", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching closet:", error)
                    return
                }
                self.closetItems = snapshot?.documents.compactMap {
                    try? $0.data(as: ClosetItem.self)
                } ?? []
            }
    }
}
