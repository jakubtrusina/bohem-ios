import Foundation
import FirebaseFirestoreSwift

struct Brand: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let logoUrl: String?
    let bannerUrl: String?
    let story: String?
    let instagram: String?
    let website: String?
    let email: String?
}

