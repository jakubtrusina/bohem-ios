//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/30/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class SliderPrefetcher: ObservableObject {
    static let shared = SliderPrefetcher()
    @Published var sliderConfigs: [String: ProductSliderConfig] = [:]

    func prefetch(sliders: [String]) async {
        let db = Firestore.firestore()

        for sliderId in sliders {
            do {
                let doc = try await db.collection("productSliders").document(sliderId).getDocument()
                if let config = try? doc.data(as: ProductSliderConfig.self) {
                    sliderConfigs[sliderId] = config
                    print("✅ Prefetched config for: \(sliderId)")
                } else {
                    print("⚠️ Failed to decode config for: \(sliderId)")
                }
            } catch {
                print("❌ Error prefetching slider \(sliderId): \(error.localizedDescription)")
            }
        }
    }

    func getConfig(for sliderId: String) -> ProductSliderConfig? {
        sliderConfigs[sliderId]
    }
}
