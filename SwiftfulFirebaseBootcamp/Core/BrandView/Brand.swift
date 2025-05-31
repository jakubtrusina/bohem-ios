import Foundation
import FirebaseFirestore

struct Brand: Identifiable, Codable {
    @DocumentID var id: String? // ✅ Already makes Brand Identifiable
    let name: String
    let description: String
    let logoUrl: String?
    let bannerUrl: String?
    let story: String?
    let instagram: String?
    let website: String?
    let email: String?
    let phone: String?
}
