//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//

import Foundation
import FirebaseFirestore

struct Return: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let orderId: String
    let reason: String
    let status: String
    let timestamp: Date
    let items: [ReturnedItem]
}
