//
//  Order.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore

struct OrderedItem: Identifiable, Codable {
    var id: String { productId + size }
    let productId: String
    let title: String
    let size: String
    let quantity: Int
    let price: Double
}

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let timestamp: Date
    let fullName: String
    let address: String
    let city: String
    let zip: String
    let phone: String
    let items: [OrderedItem]
    let total: Double
}
