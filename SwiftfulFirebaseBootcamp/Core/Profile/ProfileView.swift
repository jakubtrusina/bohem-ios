import SwiftUI
import PhotosUI
import Kingfisher


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
                                    KFImage(url)
                                        .resizable()
                                        .cancelOnDisappear(true)
                                        .fade(duration: 0.25)
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .shadow(radius: 6)

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

                        let displayName = viewModel.name.isEmpty ? NSLocalizedString("your_name", comment: "") : viewModel.name
                        Text(displayName)
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
                    ProfileSectionCard(title: NSLocalizedString("personal_info", comment: "")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("name_label", comment: "")).font(.caption).foregroundColor(.gray)
                            TextField(NSLocalizedString("name_placeholder", comment: ""), text: $viewModel.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.name) { _ in viewModel.updateUserInfo() }

                            Text(NSLocalizedString("gender_label", comment: "")).font(.caption).foregroundColor(.gray)
                            Picker("", selection: $viewModel.gender) {
                                ForEach(["", "Male", "Female", "Non-binary", "Other"], id: \ .self) { Text($0) }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: viewModel.gender) { _ in viewModel.updateUserInfo() }

                            Text(NSLocalizedString("age_label", comment: "")).font(.caption).foregroundColor(.gray)
                            TextField(NSLocalizedString("age_placeholder", comment: ""), value: $viewModel.age, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.age) { _ in viewModel.updateUserInfo() }
                        }
                    }

                    // MARK: - Measurements
                    ProfileSectionCard(title: NSLocalizedString("measurements_title", comment: "")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("height_label", comment: "")).font(.caption).foregroundColor(.gray)
                            TextField(NSLocalizedString("height_placeholder", comment: ""), value: $viewModel.height, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.height) { _ in viewModel.updateUserInfo() }

                            Text(NSLocalizedString("weight_label", comment: "")).font(.caption).foregroundColor(.gray)
                            TextField(NSLocalizedString("weight_placeholder", comment: ""), value: $viewModel.weight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .submitLabel(.done)
                                .onSubmit { viewModel.updateUserInfo() }
                                .onChange(of: viewModel.weight) { _ in viewModel.updateUserInfo() }
                        }
                    }

                    // MARK: - Fit & Size
                    ProfileSectionCard(title: NSLocalizedString("fit_size_title", comment: "")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("top_size", comment: "")).font(.caption).foregroundColor(.gray)
                            Picker(NSLocalizedString("top_size", comment: ""), selection: $viewModel.clothingSizeTop) {
                                ForEach(["", "XS", "S", "M", "L", "XL", "2XL"], id: \ .self) { Text($0) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.clothingSizeTop) { _ in viewModel.updateUserInfo() }

                            Text(NSLocalizedString("bottom_size", comment: "")).font(.caption).foregroundColor(.gray)
                            Picker(NSLocalizedString("bottom_size", comment: ""), selection: $viewModel.clothingSizeBottom) {
                                ForEach(["", "XS", "S", "M", "L", "XL"], id: \ .self) { Text($0) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: viewModel.clothingSizeBottom) { _ in viewModel.updateUserInfo() }

                            Text(NSLocalizedString("fit_preference", comment: "")).font(.caption).foregroundColor(.gray)
                            Picker(NSLocalizedString("fit_preference", comment: ""), selection: $viewModel.fitPreference) {
                                ForEach(["", "Tight", "Regular", "Loose"], id: \ .self) { Text($0) }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: viewModel.fitPreference) { _ in viewModel.updateUserInfo() }

                            NavigationLink(destination: SizeGuideView()) {
                                Text(NSLocalizedString("view_size_guide", comment: ""))
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
                        Text(NSLocalizedString("book_consultation", comment: ""))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)

                } else {
                    ProgressView(NSLocalizedString("loading_profile", comment: ""))
                        .padding(.top, 50)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("menu_profile"))
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
