//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 6/3/25.
//

import Foundation

struct PickupPoint: Hashable {
    let id: String
    let name: String
    let address: String
    let city: String
    let zip: String
    let country: String
    let latitude: Double
    let longitude: Double
}
