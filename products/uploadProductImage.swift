//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 4/18/25.
//

import FirebaseStorage

func uploadProductImage(_ imageData: Data, fileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
    let storage = Storage.storage()
    let storageRef = storage.reference().child("products/original/\(fileName)")

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    storageRef.putData(imageData, metadata: metadata) { _, error in
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}
