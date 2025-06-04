import SwiftUI

struct TabbarView: View {
    @Binding var showSignInView: Bool
    @State private var showMenu = false
    @State private var bannerTarget: BannerNavigationTarget? = nil
    @State private var selectedTab: Tab = .tryon
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationStack {
                BohemScaffold(
                    showMenu: $showMenu,
                    bannerTarget: $bannerTarget,
                    showBackButton: false,
                    onBack: nil
                ) {
                    viewForBannerTarget()
                }
            }
            .tabItem {
                Image(systemName: "cart")
                Text("Zkoušení")
            }
            .tag(Tab.tryon)

            // FAVORITES TAB
            NavigationStack {
                BohemScaffold(
                    showMenu: $showMenu,
                    bannerTarget: $bannerTarget,
                    showBackButton: false,
                    onBack: nil
                ) {
                    FavoriteView(
                        bannerTarget: $bannerTarget,
                        showMenu: $showMenu,
                        showSignInView: $showSignInView
                    )
                }
            }
            .tabItem {
                Image(systemName: "star.fill")
                Text("Oblíbené")
            }
            .tag(Tab.favorites)

            // CART TAB
            NavigationStack {
                BohemScaffold(
                    showMenu: $showMenu,
                    bannerTarget: $bannerTarget,
                    showBackButton: false,
                    onBack: nil
                ) {
                    CartView()
                }
            }
            .tabItem {
                Image(systemName: "bag")
                Text("Košík")
            }
            .tag(Tab.cart)

            // PROFILE TAB
            NavigationStack {
                BohemScaffold(
                    showMenu: $showMenu,
                    bannerTarget: $bannerTarget,
                    showBackButton: false,
                    onBack: nil
                ) {
                    ProfileView(
                        showSignInView: $showSignInView,
                        bannerTarget: $bannerTarget,
                        showMenu: $showMenu
                    )
                }
            }
            .tabItem {
                Image(systemName: "person")
                Text("Profil")
            }
            .tag(Tab.profile)
        }
        .onChange(of: bannerTarget) { target in
            print("[DEBUG] TabbarView detected bannerTarget: \(String(describing: target))")

            switch target {
            case .home, .brand, .category, .subcategory:
                if selectedTab != .tryon {
                    selectedTab = .tryon
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        bannerTarget = target
                    }
                }
            case .booking, .settings:  // ✅ ADD .settings HERE
                selectedTab = .tryon
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    bannerTarget = target
                }
            case .favorites:
                selectedTab = .favorites
            case .cart:
                selectedTab = .cart
            case .profile:
                selectedTab = .profile
            default:
                break
            }
        }

        .onAppear {
            Task {
                try? await profileViewModel.loadCurrentUser()
            }
        }
    }

    private func viewForBannerTarget() -> AnyView {
        switch bannerTarget {
        case .brand(let brand):
            return AnyView(BrandView(
                brand: brand,
                bannerTarget: $bannerTarget,
                showMenu: $showMenu
            ))

        case .category(let category):
            return AnyView(ProductsView(
                bannerTarget: $bannerTarget,
                showMenu: $showMenu,
                dismiss: dismiss,
                selectedMainCategory: category,
                selectedSubcategory: nil
            ))

        case .subcategory(let subcategory):
            return AnyView(ProductsView(
                bannerTarget: $bannerTarget,
                showMenu: $showMenu,
                dismiss: dismiss,
                selectedMainCategory: nil,
                selectedSubcategory: subcategory
            ))

        case .booking:
            if let user = profileViewModel.user, let email = user.email { let phone = user.phoneNumber ?? ""
                return AnyView(BookingView(viewModel: BookingViewModel(
                    userId: user.userId,
                    userName: profileViewModel.name,
                    userEmail: email,
                    userPhone: phone,
                    locationId: "nyc_showroom"
                )))
            } else {
                return AnyView(SettingsView(showSignInView: $showSignInView))
            }

        case .settings:
            return AnyView(SettingsView(showSignInView: $showSignInView))  // ✅ Now properly placed

        default:
            return AnyView(MainTryOnView(
                showSignInView: $showSignInView,
                bannerTarget: $bannerTarget
            ))
        }
    }
}

enum Tab {
    case tryon, favorites, cart, profile
}
