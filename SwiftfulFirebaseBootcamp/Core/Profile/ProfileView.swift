import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showPhotoActionSheet = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                if let user = viewModel.user {
                    // MARK: - Profile Header
                    VStack(spacing: 12) {
                        Button {
                            showPhotoActionSheet = true
                        } label: {
                            Group {
                                if let urlString = user.profileImagePathUrl,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .shadow(radius: 6)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 120, height: 120)
                                    }
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 120, height: 120)
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 120, height: 120)
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                    .shadow(radius: 6)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Text(viewModel.name.isEmpty ? "Your Name" : viewModel.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if let email = user.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 8)

                    // MARK: - Personal Info
                    ProfileSectionCard(title: "Personal Info") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Name").font(.caption).foregroundColor(.gray)
                            TextField("Enter your full name", text: $viewModel.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.name) { _ in viewModel.updateUserInfo() }

                            Text("Gender").font(.caption).foregroundColor(.gray)
                            Picker("", selection: $viewModel.gender) {
                                ForEach(["", "Male", "Female", "Non-binary", "Other"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: viewModel.gender) { _ in viewModel.updateUserInfo() }

                            Text("Age").font(.caption).foregroundColor(.gray)
                            TextField("Enter your age", value: $viewModel.age, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.age) { _ in viewModel.updateUserInfo() }
                        }
                    }

                    // MARK: - Measurements
                    ProfileSectionCard(title: "Body Measurements") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Height (cm)").font(.caption).foregroundColor(.gray)
                            TextField("Enter height", value: $viewModel.height, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.height) { _ in viewModel.updateUserInfo() }

                            Text("Weight (kg)").font(.caption).foregroundColor(.gray)
                            TextField("Enter weight", value: $viewModel.weight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.weight) { _ in viewModel.updateUserInfo() }
                        }
                    }

                    // MARK: - Fit & Size
                    ProfileSectionCard(title: "Fit & Size") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Top Size").font(.caption).foregroundColor(.gray)
                            Picker("Top Size", selection: $viewModel.clothingSizeTop) {
                                ForEach(["", "XS", "S", "M", "L", "XL", "2XL"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.clothingSizeTop) { _ in viewModel.updateUserInfo() }

                            Text("Bottom Size").font(.caption).foregroundColor(.gray)
                            Picker("Bottom Size", selection: $viewModel.clothingSizeBottom) {
                                ForEach(["", "XS", "S", "M", "L", "XL"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.clothingSizeBottom) { _ in viewModel.updateUserInfo() }

                            Text("Fit Preference").font(.caption).foregroundColor(.gray)
                            Picker("Fit Preference", selection: $viewModel.fitPreference) {
                                ForEach(["", "Tight", "Regular", "Loose"], id: \.self) { Text($0) }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: viewModel.fitPreference) { _ in viewModel.updateUserInfo() }

                            NavigationLink(destination: SizeGuideView()) {
                                Text("📏 View Size Guide")
                                    .font(.subheadline)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    NavigationLink(
                        destination: BookingView(
                            viewModel: BookingViewModel(
                                userId: user.userId,
                                userName: viewModel.name,
                                userEmail: user.email ?? ""
                            )
                        )
                    ) {
                        Text("📅 Book In-Store Consultation")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                } else {
                    ProgressView("Loading profile...")
                        .padding(.top, 50)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.user == nil {
                Task {
                    try? await viewModel.loadCurrentUser()
                }
            }

            let screenName = String(describing: Self.self)
            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": screenName
            ])
        }

        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: selectedItem) { newValue in
            if let newValue {
                viewModel.saveProfileImage(item: newValue)
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { image in
                Task {
                    await viewModel.saveProfileImageFromUIImage(image: image)
                }
            }
        }
        .sheet(isPresented: $showPhotoActionSheet) {
            ProfilePhotoActionSheetView(
                onChooseFromLibrary: {
                    showPhotoPicker = true
                    showPhotoActionSheet = false
                },
                onTakePhoto: {
                    showCameraPicker = true
                    showPhotoActionSheet = false
                },
                onDelete: viewModel.user?.profileImagePath != nil ? {
                    viewModel.deleteProfileImage()
                    showPhotoActionSheet = false
                } : nil,
                onCancel: {
                    showPhotoActionSheet = false
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView(showSignInView: $showSignInView)
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }
}

struct ProfileSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, -4)
    }
}

struct AlertMessage: Identifiable {
    let id = UUID()
    let text: String
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
