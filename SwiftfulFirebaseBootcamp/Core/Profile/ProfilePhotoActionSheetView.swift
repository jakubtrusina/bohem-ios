import SwiftUI

struct ProfilePhotoActionSheetView: View {
    let onChooseFromLibrary: () -> Void
    let onTakePhoto: () -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 10)

            Text("Change Profile Photo")
                .font(.headline)
                .padding(.top, 10)

            VStack(spacing: 0) {
                Button(action: onChooseFromLibrary) {
                    Text("Choose from Library")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.white)

                Divider()

                Button(action: onTakePhoto) {
                    Text("Take Photo")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.white)

                if let onDelete = onDelete {
                    Divider()

                    Button(role: .destructive, action: onDelete) {
                        Text("Delete Photo")
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.white)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.top, 12)
            .padding(.horizontal)

            Button("Cancel", role: .cancel, action: onCancel)
                .font(.system(size: 17))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.top, 8)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
}
