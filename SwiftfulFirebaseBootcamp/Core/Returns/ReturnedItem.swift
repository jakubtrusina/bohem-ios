//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation

struct ReturnedItem: Identifiable, Codable {
    var id: String { productId + size }
    let productId: String
    let title: String
    let size: String
    let quantity: Int
}
