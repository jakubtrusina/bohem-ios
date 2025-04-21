import SwiftUI

struct BrandUploadView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var logoUrl = ""
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Brand Info")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Logo URL (optional)", text: $logoUrl)
                }

                Button("Upload to Firestore") {
                    Task {
                        let brand = Brand(
                            id: nil,
                            name: name,
                            description: description,
                            logoUrl: logoUrl.isEmpty ? nil : logoUrl
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
            .navigationTitle("Add Brand")
        }
    }
}
