//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/21/25.
//

import SwiftUI

struct UploadProductsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Upload Products to Firestore")
                .font(.headline)

            Button("🚀 Upload from JSON") {
                uploadLocalJSONToFirestore()
            }
        }
        .padding()
    }

    func uploadLocalJSONToFirestore() {
        guard let url = Bundle.main.url(forResource: "firestore_products_cleaned_strict", withExtension: "json")
 else {
            print("❌ Could not find local JSON file in bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: Product].self, from: data)

            Task {
                for (_, product) in decoded {
                    do {
                        try await ProductsManager.shared.uploadProduct(product: product)
                        print("✅ Uploaded: \(product.title)")
                    } catch {
                        print("❌ Upload failed for \(product.title): \(error)")
                    }
                }
            }
        } catch {
            print("❌ Error decoding JSON: \(error)")
        }
    }
}

