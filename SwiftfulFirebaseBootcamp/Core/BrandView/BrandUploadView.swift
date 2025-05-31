import SwiftUI

struct BrandUploadView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var logoUrl = ""
    @State private var bannerUrl = ""
    @State private var story = ""
    @State private var instagram = ""
    @State private var website = ""
    @State private var email = ""
    @State private var successMessage: String?
    @State private var phone = ""


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Brand Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Logo URL", text: $logoUrl)
                    TextField("Banner URL", text: $bannerUrl)
                }

                Section(header: Text("Story")) {
                    TextEditor(text: $story)
                        .frame(minHeight: 80)
                }

                Section(header: Text("Contact & Social")) {
                    TextField("Instagram Handle (no @)", text: $instagram)
                    TextField("Website", text: $website)
                    TextField("Email", text: $email)
                    TextField("Phone Number", text: $phone)

                }

                Button("Upload to Firestore") {
                    Task {
                        let brand = Brand(
                            id: nil,
                            name: name,
                            description: description,
                            logoUrl: logoUrl.isEmpty ? nil : logoUrl,
                            bannerUrl: bannerUrl.isEmpty ? nil : bannerUrl,
                            story: story.isEmpty ? nil : story,
                            instagram: instagram.isEmpty ? nil : instagram,
                            website: website.isEmpty ? nil : website,
                            email: email.isEmpty ? nil : email,
                            phone: phone.isEmpty ? nil : phone // ✅ Added here

                        )

                        do {
                            try await BrandManager.shared.uploadBrand(brand)
                            successMessage = "✅ \(name) uploaded!"
                        } catch {
                            successMessage = "❌ Upload failed: \(error.localizedDescription)"
                        }
                    }
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(successMessage.contains("✅") ? .green : .red)
                }
            }
            .navigationTitle("Add / Edit Brand")
        }
    }
}
