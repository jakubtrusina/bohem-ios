//
//  UserManager.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Nick Sarno on 1/21/23.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth


struct Movie: Codable {
    let id: String
    let title: String
    let isPopular: Bool
}

struct DBUser: Codable {
    let userId: String
    let isAnonymous: Bool?
    let email: String?
    let photoUrl: String?
    let dateCreated: Date?
    let isPremium: Bool?
    let preferences: [String]?
    let favoriteMovie: Movie?
    let profileImagePath: String?
    let profileImagePathUrl: String?

    // NEW FIELDS
    let name: String?
    let gender: String?
    let age: Int?
    let height: Double?
    let weight: Double?
    let bodyShape: String?
    let clothingSizeTop: String?
    let clothingSizeBottom: String?
    let fitPreference: String?

    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.isAnonymous = auth.isAnonymous
        self.email = auth.email
        self.photoUrl = auth.photoUrl
        self.dateCreated = Date()
        self.isPremium = false
        self.preferences = nil
        self.favoriteMovie = nil
        self.profileImagePath = nil
        self.profileImagePathUrl = nil

        // Defaults
        self.name = nil
        self.gender = nil
        self.age = nil
        self.height = nil
        self.weight = nil
        self.bodyShape = nil
        self.clothingSizeTop = nil
        self.clothingSizeBottom = nil
        self.fitPreference = nil
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isAnonymous = "is_anonymous"
        case email = "email"
        case photoUrl = "photo_url"
        case dateCreated = "date_created"
        case isPremium = "user_isPremium"
        case preferences = "preferences"
        case favoriteMovie = "favorite_movie"
        case profileImagePath = "profile_image_path"
        case profileImagePathUrl = "profile_image_path_url"

        // NEW KEYS
        case name = "name"
        case gender = "gender"
        case age = "age"
        case height = "height"
        case weight = "weight"
        case bodyShape = "body_shape"
        case clothingSizeTop = "clothing_size_top"
        case clothingSizeBottom = "clothing_size_bottom"
        case fitPreference = "fit_preference"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
        self.preferences = try container.decodeIfPresent([String].self, forKey: .preferences)
        self.favoriteMovie = try container.decodeIfPresent(Movie.self, forKey: .favoriteMovie)
        self.profileImagePath = try container.decodeIfPresent(String.self, forKey: .profileImagePath)
        self.profileImagePathUrl = try container.decodeIfPresent(String.self, forKey: .profileImagePathUrl)

        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.age = try container.decodeIfPresent(Int.self, forKey: .age)
        self.height = try container.decodeIfPresent(Double.self, forKey: .height)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.bodyShape = try container.decodeIfPresent(String.self, forKey: .bodyShape)
        self.clothingSizeTop = try container.decodeIfPresent(String.self, forKey: .clothingSizeTop)
        self.clothingSizeBottom = try container.decodeIfPresent(String.self, forKey: .clothingSizeBottom)
        self.fitPreference = try container.decodeIfPresent(String.self, forKey: .fitPreference)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encodeIfPresent(self.isAnonymous, forKey: .isAnonymous)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoUrl, forKey: .photoUrl)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.isPremium, forKey: .isPremium)
        try container.encodeIfPresent(self.preferences, forKey: .preferences)
        try container.encodeIfPresent(self.favoriteMovie, forKey: .favoriteMovie)
        try container.encodeIfPresent(self.profileImagePath, forKey: .profileImagePath)
        try container.encodeIfPresent(self.profileImagePathUrl, forKey: .profileImagePathUrl)

        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.gender, forKey: .gender)
        try container.encodeIfPresent(self.age, forKey: .age)
        try container.encodeIfPresent(self.height, forKey: .height)
        try container.encodeIfPresent(self.weight, forKey: .weight)
        try container.encodeIfPresent(self.bodyShape, forKey: .bodyShape)
        try container.encodeIfPresent(self.clothingSizeTop, forKey: .clothingSizeTop)
        try container.encodeIfPresent(self.clothingSizeBottom, forKey: .clothingSizeBottom)
        try container.encodeIfPresent(self.fitPreference, forKey: .fitPreference)
    }
}


final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private let userCollection: CollectionReference = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    private func userFavoriteProductCollection(userId: String) -> CollectionReference {
        userDocument(userId: userId).collection("favorite_products")
    }
    
    private func userFavoriteProductDocument(userId: String, favoriteProductId: String) -> DocumentReference {
        userFavoriteProductCollection(userId: userId).document(favoriteProductId)
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
//        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private var userFavoriteProductsListener: ListenerRegistration? = nil
    
    func createNewUser(user: DBUser) async throws {
        let docRef = userDocument(userId: user.userId)
        let snapshot = try await docRef.getDocument()
        if snapshot.exists {
            return  // Don't overwrite existing user
        }
        try docRef.setData(from: user, merge: true) // Always write, even if exists (temporarily)
    }
   
    
//    func createNewUser(auth: AuthDataResultModel) async throws {
//        var userData: [String:Any] = [
//            "user_id" : auth.uid,
//            "is_anonymous" : auth.isAnonymous,
//            "date_created" : Timestamp(),
//        ]
//        if let email = auth.email {
//            userData["email"] = email
//        }
//        if let photoUrl = auth.photoUrl {
//            userData["photo_url"] = photoUrl
//        }
//
//        try await userDocument(userId: auth.uid).setData(userData, merge: false)
//    }
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
//    func getUser(userId: String) async throws -> DBUser {
//        let snapshot = try await userDocument(userId: userId).getDocument()
//
//        guard let data = snapshot.data(), let userId = data["user_id"] as? String else {
//            throw URLError(.badServerResponse)
//        }
//
//        let isAnonymous = data["is_anonymous"] as? Bool
//        let email = data["email"] as? String
//        let photoUrl = data["photo_url"] as? String
//        let dateCreated = data["date_created"] as? Date
//
//        return DBUser(userId: userId, isAnonymous: isAnonymous, email: email, photoUrl: photoUrl, dateCreated: dateCreated)
//    }
    
//    func updateUserPremiumStatus(user: DBUser) async throws {
//        try userDocument(userId: user.userId).setData(from: user, merge: true)
//    }
    
    func updateUserPremiumStatus(userId: String, isPremium: Bool) async throws {
        let data: [String:Any] = [
            DBUser.CodingKeys.isPremium.rawValue : isPremium,
        ]

        try await userDocument(userId: userId).updateData(data)
    }
    
    func updateUserProfileImagePath(userId: String, path: String?, url: String?) async throws {
        let data: [String:Any] = [
            DBUser.CodingKeys.profileImagePath.rawValue : path,
            DBUser.CodingKeys.profileImagePathUrl.rawValue : url,
        ]

        try await userDocument(userId: userId).updateData(data)
    }
    func addUserCartProduct(userId: String, product: Product, size: String, quantity: Int) async throws {
        guard let productSize = product.sizes?.first(where: { $0.size == size }) else {
            print("❌ Size \(size) not found for product \(product.id)")
            return
        }

        let cartItem = CartItem(id: UUID().uuidString, product: product, size: productSize, quantity: quantity)
        let docId = cartItem.id
        let document = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("cart_products")
            .document(docId)

        let data = try Firestore.Encoder().encode(cartItem)
        try await document.setData(data, merge: false)
    }

    func getFollowerCount(for brandName: String) async -> Int {
        do {
            let snapshot = try await Firestore.firestore()
                .collectionGroup("followed_brands")
                .whereField(FieldPath.documentID(), isEqualTo: brandName)
                .getDocuments()

            return snapshot.count
        } catch {
            print("❌ Failed to fetch follower count: \(error)")
            return 0
        }
    }

    
    func followBrand(userId: String, brandName: String) async throws {
        let ref = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("followed_brands")
            .document(brandName)
        
        try await ref.setData([
            "followedAt": Timestamp()
        ])
    }

    func unfollowBrand(userId: String, brandName: String) async throws {
        let ref = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("followed_brands")
            .document(brandName)
        
        try await ref.delete()
    }

    func isFollowingBrand(brandName: String) async -> Bool {
        guard let user = try? AuthenticationManager.shared.getAuthenticatedUser() else { return false }

        let docRef = Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .collection("followed_brands")
            .document(brandName)

        do {
            let snapshot = try await docRef.getDocument()
            return snapshot.exists
        } catch {
            print("❌ Failed to check if following brand: \(error)")
            return false
        }
    }



    
    func addUserPreference(userId: String, preference: String) async throws {
        let data: [String:Any] = [
            DBUser.CodingKeys.preferences.rawValue : FieldValue.arrayUnion([preference])
        ]

        try await userDocument(userId: userId).updateData(data)
    }
    
    func removeUserPreference(userId: String, preference: String) async throws {
        let data: [String:Any] = [
            DBUser.CodingKeys.preferences.rawValue : FieldValue.arrayRemove([preference])
        ]

        try await userDocument(userId: userId).updateData(data)
    }
    
    func addFavoriteMovie(userId: String, movie: Movie) async throws {
        guard let data = try? encoder.encode(movie) else {
            throw URLError(.badURL)
        }
        
        let dict: [String:Any] = [
            DBUser.CodingKeys.favoriteMovie.rawValue : data
        ]

        try await userDocument(userId: userId).updateData(dict)
    }
    
    func removeFavoriteMovie(userId: String) async throws {
        let data: [String:Any?] = [
            DBUser.CodingKeys.favoriteMovie.rawValue : nil
        ]

        try await userDocument(userId: userId).updateData(data as [AnyHashable : Any])
    }
    
    func addUserFavoriteProduct(userId: String, productId: String) async throws {
        let document = userFavoriteProductCollection(userId: userId).document()
        let documentId = document.documentID
        
        let data: [String:Any] = [
            UserFavoriteProduct.CodingKeys.id.rawValue : documentId,
            UserFavoriteProduct.CodingKeys.productId.rawValue : productId,
            UserFavoriteProduct.CodingKeys.dateCreated.rawValue : Timestamp()
        ]
        
        try await document.setData(data, merge: false)
    }
    
    func removeUserFavoriteProduct(userId: String, favoriteProductId: String) async throws {
        try await userFavoriteProductDocument(userId: userId, favoriteProductId: favoriteProductId).delete()
    }
    func removeUserFavoriteProductByProductId(userId: String, productId: String) async throws {
        let snapshot = try await userFavoriteProductCollection(userId: userId)
            .whereField("product_id", isEqualTo: productId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }

    
    func getAllUserFavoriteProducts(userId: String) async throws -> [UserFavoriteProduct] {
        try await userFavoriteProductCollection(userId: userId).getDocuments(as: UserFavoriteProduct.self)
    }
    
    func getAllUserCartProducts(userId: String) async throws -> [CartItem] {
        let snapshot = try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("cart_products")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CartItem.self) }
    }

    func removeUserCartProduct(userId: String, productId: String) async throws {
        try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("cart_products")
            .document(String(productId))
            .delete()
    }

    func fetchClosetProductIds() async -> [String] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        let ref = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("closet")

        do {
            let snapshot = try await ref.getDocuments()
            return snapshot.documents.map { $0.documentID }
        } catch {
            print("❌ Error fetching closet: \(error)")
            return []
        }
    }

    
    func removeListenerForAllUserFavoriteProducts() {
        self.userFavoriteProductsListener?.remove()
    }
    
    func addListenerForAllUserFavoriteProducts(userId: String, completion: @escaping (_ products: [UserFavoriteProduct]) -> Void) {
        self.userFavoriteProductsListener = userFavoriteProductCollection(userId: userId).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            let products: [UserFavoriteProduct] = documents.compactMap({ try? $0.data(as: UserFavoriteProduct.self) })
            completion(products)
            
            querySnapshot?.documentChanges.forEach { diff in
                if (diff.type == .added) {
                    print("New products: \(diff.document.data())")
                }
                if (diff.type == .modified) {
                    print("Modified products: \(diff.document.data())")
                }
                if (diff.type == .removed) {
                    print("Removed products: \(diff.document.data())")
                }
            }
        }
    }
    
//    func addListenerForAllUserFavoriteProducts(userId: String) -> AnyPublisher<[UserFavoriteProduct], Error> {
//        let publisher = PassthroughSubject<[UserFavoriteProduct], Error>()
//
//        self.userFavoriteProductsListener = userFavoriteProductCollection(userId: userId).addSnapshotListener { querySnapshot, error in
//            guard let documents = querySnapshot?.documents else {
//                print("No documents")
//                return
//            }
//
//            let products: [UserFavoriteProduct] = documents.compactMap({ try? $0.data(as: UserFavoriteProduct.self) })
//            publisher.send(products)
//        }
//
//        return publisher.eraseToAnyPublisher()
//    }
    func addListenerForAllUserFavoriteProducts(userId: String) -> AnyPublisher<[UserFavoriteProduct], Error> {
        let (publisher, listener) = userFavoriteProductCollection(userId: userId)
            .addSnapshotListener(as: UserFavoriteProduct.self)
        
        self.userFavoriteProductsListener = listener
        return publisher
    }
    
}
import Combine

struct UserFavoriteProduct: Codable {
    let id: String
    let productId: String
    let dateCreated: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case productId = "product_id"
        case dateCreated = "date_created"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.productId = try container.decode(String.self, forKey: .productId)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.productId, forKey: .productId)
        try container.encode(self.dateCreated, forKey: .dateCreated)
    }
}

