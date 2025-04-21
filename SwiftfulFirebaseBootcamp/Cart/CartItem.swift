//
//  CartItem.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/12/25.
//

import FirebaseFirestoreSwift

struct CartItem: Identifiable, Codable {
    @DocumentID var id: String?  // Assigned automatically when reading from Firestore
    let product: Product
    let size: String
    var quantity: Int
}
