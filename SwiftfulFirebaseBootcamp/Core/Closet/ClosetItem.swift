//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/25/25.
//
import FirebaseFirestore
import Foundation

struct ClosetItem: Identifiable, Codable, Hashable {
    @DocumentID var id: String?  // e.g., productId-size
    let productId: String
    let title: String
    let imageUrl: String
    let size: String
    let addedDate: Date
}
