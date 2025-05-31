import SwiftUI
import PhotosUI
import Kingfisher
import ConfettiSwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    @Binding var bannerTarget: BannerNavigationTarget?
    @Binding var showMenu: Bool

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showPhotoActionSheet = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var confettiCounter = 0
    @State private var didAlreadyCelebrate = false
    @State private var showCompletionOverlay = false

    private let profileCelebrationKey = "didCelebrateProfileCompletion"

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationBarBackButtonHidden(true)
                .onAppear {
                    if viewModel.user == nil {
                        Task { try? await viewModel.loadCurrentUser() }
                    }

                    AnalyticsManager.shared.logEvent(.screenView, params: [
                        "screen_name": "ProfileView"
                    ])
                    if let uid = viewModel.user?.userId {
                        AnalyticsManager.shared.setUserId(uid)
                    }

                    if viewModel.profileCompletion < 60 {
                        showCompletionOverlay = true
                        AnalyticsManager.shared.logCustomEvent(name: "profile_nudged", params: [
                            "reason": "low_completion",
                            "completion": viewModel.profileCompletion
                        ])
                    }

                    didAlreadyCelebrate = UserDefaults.standard.bool(forKey: profileCelebrationKey)
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: selectedItem) { newValue in
                    if let newValue { viewModel.saveProfileImage(item: newValue) }
                }
                .onChange(of: viewModel.profileCompletion) { newValue in
                    let alreadyCelebrated = UserDefaults.standard.bool(forKey: profileCelebrationKey)
                    if newValue == 100 && !alreadyCelebrated {
                        confettiCounter += 1
                        didAlreadyCelebrate = true
                        UserDefaults.standard.set(true, forKey: profileCelebrationKey)

                        AnalyticsManager.shared.logCustomEvent(name: "profile_completed", params: [
                            "user_id": viewModel.user?.userId ?? "unknown",
                            "completion": 100
                        ])
                    }
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
                .sheet(isPresented: $showCameraPicker) {
                    ImagePicker(sourceType: .camera, onImagePicked: { image in
                        Task { await viewModel.saveProfileImageFromUIImage(image: image) }
                    })
                }
                .sheet(isPresented: $showPhotoActionSheet) {
                    ProfilePhotoActionSheetView(
                        onChooseFromLibrary: { showPhotoPicker = true; showPhotoActionSheet = false },
                        onTakePhoto: { showCameraPicker = true; showPhotoActionSheet = false },
                        onDelete: viewModel.user?.profileImagePath != nil ? {
                            viewModel.deleteProfileImage(); showPhotoActionSheet = false
                        } : nil,
                        onCancel: { showPhotoActionSheet = false }
                    )
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                profileHeader
                if viewModel.user != nil {
                    quickLinksSection
                    compactInfoTable
                } else {
                    ProgressView("Načítání profilu...").padding(.top, 50)
                }
                ConfettiCannon(
                    trigger: $confettiCounter,
                    colors: [.red, .green, .yellow, .blue],
                    confettiSize: 12,
                    rainHeight: UIScreen.main.bounds.height,
                    radius: 600,
                    repetitions: 1,
                    repetitionInterval: 0.2
                )
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Button { showPhotoActionSheet = true } label: {
                Group {
                    if let urlString = viewModel.user?.profileImagePathUrl,
                       let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle().fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                Text("👋 Vítejte")
                    .font(.headline)
                    .foregroundColor(.black)
                TextField("Zadejte své jméno", text: $viewModel.name)
                    .font(.title3.weight(.medium))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                    .onChange(of: viewModel.name) { _ in
                        viewModel.updateUserInfo()
                    }
            }
            if let email = viewModel.user?.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if viewModel.profileCompletion < 100 {
                ProgressView(value: Double(viewModel.profileCompletion), total: 100)
                Text("Profil je dokončen na \(viewModel.profileCompletion)%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    private var quickLinksSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                NavigationLink(destination: FavoriteView(
                    bannerTarget: $bannerTarget,
                    showMenu: $showMenu,
                    showSignInView: $showSignInView
                )) {
                    quickLinkCard(icon: "heart.fill", title: "Oblíbené")
                }
                NavigationLink(destination: TryOnHistoryView()) {
                    quickLinkCard(icon: "sparkles", title: "Zkoušené")
                }
                NavigationLink(destination: ClosetView()) {
                    quickLinkCard(icon: "bag.fill", title: "Šatník")
                }
            }
            HStack(spacing: 20) {
                NavigationLink(destination: OrdersView()) {
                    quickLinkCard(icon: "cube.box.fill", title: "Objednávky")
                }
                NavigationLink(destination: ReturnsView()) {
                    quickLinkCard(icon: "arrow.uturn.backward", title: "Vrácení")
                }
                NavigationLink(destination: RezervaceListView(viewModel: viewModel)) {
                    quickLinkCard(icon: "calendar", title: "Rezervace")
                }
            }
        }
    }


    private var compactInfoTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vyplňte své údeje, abychom vám mohli nabídnout přesnější doporučení velikostí, střihu a stylu.")
                .font(.caption2)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink(destination: SizeGuideView()) {
                Label("Tabulka velikostí", systemImage: "ruler")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.black)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 16), count: 3), spacing: 16) {
                editableMenuPickerCell(title: "Velikost vršku", selection: $viewModel.clothingSizeTop)
                editableMenuPickerCell(title: "Velikost spodku", selection: $viewModel.clothingSizeBottom)
                editableNumberCell(title: "Výška", value: $viewModel.height, unit: "cm")
                editableNumberCell(title: "Váha", value: $viewModel.weight, unit: "kg")
                editableAgeCell(title: "Věk", value: $viewModel.age)
                editableMenuPickerCell(title: "Pohlaví", selection: $viewModel.gender, options: ["", "Muž", "Žena", "Jiné"])
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .padding(.top)
    }

    private func editableMenuPickerCell(title: String, selection: Binding<String>, options: [String] = ["", "XS", "S", "M", "L", "XL", "2XL"]) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option.isEmpty ? "-" : option) {
                        selection.wrappedValue = option
                        viewModel.updateUserInfo()
                        AnalyticsManager.shared.logCustomEvent(name: "profile_field_edited", params: [
                            "field": title,
                            "value": option
                        ])

                    }
                }
            } label: {
                Text(selection.wrappedValue.isEmpty ? "-" : selection.wrappedValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .frame(height: 36)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func editableNumberCell(title: String, value: Binding<Double?>, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField("-", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .onChange(of: value.wrappedValue) { newValue in
                    viewModel.updateUserInfo()
                    if let value = newValue {
                        AnalyticsManager.shared.logCustomEvent(name: "profile_field_edited", params: [
                            "field": title,
                            "value": "\(value)"
                        ])
                    }
                }

            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func editableAgeCell(title: String, value: Binding<Int?>) -> some View {
        let text = Binding<String>(
            get: { value.wrappedValue.map(String.init) ?? "" },
            set: { value.wrappedValue = Int($0) }
        )
        return VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField("-", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { newValue in
                    viewModel.updateUserInfo()
                    AnalyticsManager.shared.logCustomEvent(name: "profile_field_edited", params: [
                        "field": title,
                        "value": newValue
                    ])
                }

        }
        .frame(maxWidth: .infinity)
    }

    private func quickLinkCard(icon: String, title: String) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.black)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(.footnote)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
}
