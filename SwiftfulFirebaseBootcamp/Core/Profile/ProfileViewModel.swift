import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var saveSuccessMessage: AlertMessage? = nil
    @Published private(set) var user: DBUser? = nil

    // MARK: - User Info Fields
    @Published var name: String = ""
    @Published var gender: String = ""
    @Published var age: Int?
    @Published var height: Double?
    @Published var weight: Double?
    @Published var bodyShape: String = ""
    @Published var clothingSizeTop: String = ""
    @Published var clothingSizeBottom: String = ""
    @Published var fitPreference: String = ""

    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let fetchedUser = try await UserManager.shared.getUser(userId: authDataResult.uid)
        self.user = fetchedUser

        // Populate form fields
        self.name = fetchedUser.name ?? ""
        self.gender = fetchedUser.gender ?? ""
        self.age = fetchedUser.age
        self.height = fetchedUser.height
        self.weight = fetchedUser.weight
        self.bodyShape = fetchedUser.bodyShape ?? ""
        self.clothingSizeTop = fetchedUser.clothingSizeTop ?? ""
        self.clothingSizeBottom = fetchedUser.clothingSizeBottom ?? ""
        self.fitPreference = fetchedUser.fitPreference ?? ""
        
        AnalyticsManager.shared.setUserProperties(from: fetchedUser)

        print("🔥 Setting user properties for:", fetchedUser.userId)
        print("🔥 Gender:", fetchedUser.gender ?? "nil")
        print("🔥 Age:", fetchedUser.age ?? -1)
        print("🔥 Body shape:", fetchedUser.bodyShape ?? "nil")
        print("🔥 Fit preference:", fetchedUser.fitPreference ?? "nil")

        
    }

    func updateUserInfo() {
        guard let user else { return }

        Task {
            let data: [String: Any] = [
                DBUser.CodingKeys.name.rawValue: name,
                DBUser.CodingKeys.gender.rawValue: gender,
                DBUser.CodingKeys.age.rawValue: age as Any,
                DBUser.CodingKeys.height.rawValue: height as Any,
                DBUser.CodingKeys.weight.rawValue: weight as Any,
                DBUser.CodingKeys.bodyShape.rawValue: bodyShape,
                DBUser.CodingKeys.clothingSizeTop.rawValue: clothingSizeTop,
                DBUser.CodingKeys.clothingSizeBottom.rawValue: clothingSizeBottom,
                DBUser.CodingKeys.fitPreference.rawValue: fitPreference
            ]

            try await Firestore.firestore()
                .collection("users")
                .document(user.userId)
                .updateData(data)

            self.user = try await UserManager.shared.getUser(userId: user.userId)
            self.saveSuccessMessage = AlertMessage(text: "Profile updated successfully!")
        }
        AnalyticsManager.shared.setUserProperties(from: self.user!)
    }
    
    

    func saveProfileImage(item: PhotosPickerItem) {
        guard let user else { return }

        Task {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }

            let (path, _) = try await StorageManager.shared.saveImage(data: data, userId: user.userId)
            let url = try await StorageManager.shared.getUrlForImage(path: path)

            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path, url: url.absoluteString)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func saveProfileImageFromUIImage(image: UIImage) async {
        guard let user else { return }

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to compress camera image")
            return
        }

        do {
            let (path, _) = try await StorageManager.shared.saveImage(data: data, userId: user.userId)
            let url = try await StorageManager.shared.getUrlForImage(path: path)

            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path, url: url.absoluteString)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        } catch {
            print("❌ Error saving image from camera:", error)
        }
    }

    func deleteProfileImage() {
        guard let user, let path = user.profileImagePath else { return }

        Task {
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: nil, url: nil)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func togglePremiumStatus() {
        guard let user else { return }

        Task {
            let currentValue = user.isPremium ?? false
            try await UserManager.shared.updateUserPremiumStatus(userId: user.userId, isPremium: !currentValue)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func addUserPreference(text: String) {
        guard let user else { return }

        Task {
            try await UserManager.shared.addUserPreference(userId: user.userId, preference: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func removeUserPreference(text: String) {
        guard let user else { return }

        Task {
            try await UserManager.shared.removeUserPreference(userId: user.userId, preference: text)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func addFavoriteMovie() {
        guard let user else { return }

        Task {
            let movie = Movie(id: "1", title: "Avatar 2", isPopular: true)
            try await UserManager.shared.addFavoriteMovie(userId: user.userId, movie: movie)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }

    func removeFavoriteMovie() {
        guard let user else { return }

        Task {
            try await UserManager.shared.removeFavoriteMovie(userId: user.userId)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }

}
