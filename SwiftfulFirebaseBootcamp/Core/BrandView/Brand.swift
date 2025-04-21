//
//  Brand.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/11/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Brand: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let logoUrl: String?
    
    static func ==(lhs: Brand, rhs: Brand) -> Bool {
        return lhs.id == rhs.id
    }
}
