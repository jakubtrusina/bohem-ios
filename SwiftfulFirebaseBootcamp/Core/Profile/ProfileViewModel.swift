import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var saveSuccessMessage: AlertMessage? = nil
    @Published private(set) var user: DBUser? = nil

    // User Profile Fields
    @Published var name: String = ""
    @Published var gender: String = ""
    @Published var age: Int?
    @Published var height: Double?
    @Published var weight: Double?
    @Published var bodyShape: String = ""
    @Published var clothingSizeTop: String = ""
    @Published var clothingSizeBottom: String = ""
    @Published var fitPreference: String = ""

    // Reservations
    @Published var rezervace: [Rezervace] = []

    // Managers
    let rezervaceNotificationManager = RezervaceNotificationManager()

    // MARK: - Load User

    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let fetchedUser = try await UserManager.shared.getUser(userId: authDataResult.uid)
        self.user = fetchedUser

        name = fetchedUser.name ?? ""
        gender = fetchedUser.gender ?? ""
        age = fetchedUser.age
        height = fetchedUser.height
        weight = fetchedUser.weight
        bodyShape = fetchedUser.bodyShape ?? ""
        clothingSizeTop = fetchedUser.clothingSizeTop ?? ""
        clothingSizeBottom = fetchedUser.clothingSizeBottom ?? ""
        fitPreference = fetchedUser.fitPreference ?? ""

        AnalyticsManager.shared.setUserProperties(from: fetchedUser)

        print("🔥 Loaded user: \(fetchedUser.userId)")
    }

    // MARK: - Update User Info

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
            self.saveSuccessMessage = AlertMessage(text: "Profil byl úspěšně aktualizován!")
        }

        AnalyticsManager.shared.setUserProperties(from: self.user!)
    }

    // MARK: - Rezervace

    func loadRezervace() async {
        guard let userId = user?.userId else { return }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("rezervace")
                .order(by: "date", descending: false)
                .getDocuments()

            rezervace = snapshot.documents.compactMap { doc in
                let data = doc.data()
                return Rezervace(
                    id: doc.documentID,
                    date: data["date"] as? String ?? "",
                    time: data["time"] as? String ?? "",
                    reason: data["reason"] as? String ?? "",
                    confirmed: data["confirmed"] as? Bool ?? false,
                    locationName: data["locationName"] as? String ?? "Neznámé místo"
                )
            }

        } catch {
            print("❌ Chyba při načítání rezervací: \(error)")
        }
    }

    func deleteRezervace(_ rezervace: Rezervace) async {
        guard let userId = user?.userId else { return }

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("rezervace")
                .document(rezervace.id)
                .delete()

            rezervaceNotificationManager.cancelNotification(for: rezervace)
            await loadRezervace()
        } catch {
            print("❌ Chyba při mazání rezervace: \(error)")
        }
    }

    // MARK: - Profile Image

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
            print("❌ Nepodařilo se zkomprimovat obrázek")
            return
        }

        do {
            let (path, _) = try await StorageManager.shared.saveImage(data: data, userId: user.userId)
            let url = try await StorageManager.shared.getUrlForImage(path: path)

            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path, url: url.absoluteString)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        } catch {
            print("❌ Chyba při ukládání obrázku z kamery: \(error)")
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

    // MARK: - Other User Features

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

    // MARK: - Supporting Models

    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }

    struct Rezervace: Identifiable {
        var id: String
        var date: String
        var time: String
        var reason: String
        var confirmed: Bool
        var locationName: String
        var fullDateTime: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.date(from: "\(date) \(time)")
        }

    }

    // MARK: - Profile Completion

    var profileCompletion: Int {
        let totalFields = 7
        var filled = 0
        if !name.isEmpty { filled += 1 }
        if !gender.isEmpty { filled += 1 }
        if age != nil { filled += 1 }
        if height != nil { filled += 1 }
        if weight != nil { filled += 1 }
        if !clothingSizeTop.isEmpty { filled += 1 }
        if !clothingSizeBottom.isEmpty { filled += 1 }
        return Int((Double(filled) / Double(totalFields)) * 100)
    }
}
