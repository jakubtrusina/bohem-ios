import SwiftUI

struct BohemHeaderBar: View {
    @ObservedObject var cartManager = CartManager.shared
    @State private var animateCart = false

    let showBackButton: Bool
    let onBack: (() -> Void)?
    let onNavigate: (BannerNavigationTarget) -> Void
    let onToggleMenu: () -> Void

    var body: some View {
        HStack {
            if showBackButton, let onBack = onBack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Zpět")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.05))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .padding(.leading, 20)
            } else {
                Button(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "BohemHeaderBar",
                        "button_id": "home_logo"
                    ])
                    onNavigate(.home)
                }) {
                    Image("LOGO")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .padding(10)
                        .contentShape(Rectangle())
                }
                .padding(.leading, 20)
            }

            Spacer()

            HStack(spacing: 16) {
                headerIcon(systemName: "heart", id: "favorites", action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "BohemHeaderBar", "button_id": "favorites"
                    ])
                    onNavigate(.favorites)
                })
                cartIcon(action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "BohemHeaderBar", "button_id": "cart"
                    ])
                    onNavigate(.cart)
                })
                headerIcon(systemName: "person", id: "profile", action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "BohemHeaderBar", "button_id": "profile"
                    ])
                    onNavigate(.profile)
                })
                headerIcon(systemName: "line.3.horizontal", id: "menu", action: {
                    AnalyticsManager.shared.logEvent(.buttonClick, params: [
                        "screen": "BohemHeaderBar", "button_id": "menu"
                    ])
                    onToggleMenu()
                })
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 1)
        .padding(.vertical, 2)
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .zIndex(10)
        .onChange(of: cartManager.cartItems.count) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animateCart = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animateCart = false
            }
        }
    }

    private func headerIcon(systemName: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.black)
        }
    }

    private func cartIcon(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bag")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.black)
                    .scaleEffect(animateCart ? 1.3 : 1.0)

                if cartManager.cartItems.count > 0 {
                    Text("\(cartManager.cartItems.count)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                        .transition(.scale)
                }
            }
        }
    }
}

struct BohemScaffold<Content: View>: View {
    @Binding var showMenu: Bool
    @Binding var bannerTarget: BannerNavigationTarget?

    let showBackButton: Bool
    let onBack: (() -> Void)?
    let content: () -> Content

    @State private var expandedCategory: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                BohemHeaderBar(
                    showBackButton: showBackButton,
                    onBack: onBack,
                    onNavigate: handleHeaderNavigation,
                    onToggleMenu: { showMenu.toggle() }
                )
                content()
            }

            if showMenu {
                SideMenu(
                    isVisible: $showMenu,
                    expandedCategory: $expandedCategory,
                    onCategorySelected: handleCategorySelection,
                    onBrandSelected: handleBrandSelection,
                    onProfileTapped: handleProfileTap,
                    onSettingsTapped: handleSettingsTap
                )
                .frame(width: 300)
                .background(Color.white)
                .offset(y: 70)
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }

    // MARK: - Header Navigation Handler
    private func handleHeaderNavigation(_ target: BannerNavigationTarget) {
        print("[DEBUG] Header navigation to: \(target)")
        AnalyticsManager.shared.logEvent(.buttonClick, params: [
            "screen": "BohemHeaderBar",
            "target": "\(target)"
        ])

        bannerTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            bannerTarget = target
        }
    }

    // MARK: - Side Menu Handlers
    private func handleCategorySelection(main: String, sub: String?) {
        AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
            "screen": "SideMenu",
            "main_category": main,
            "subcategory": sub ?? "none"
        ])

        bannerTarget = sub != nil ? .subcategory(sub!) : .category(main)
        showMenu = false
    }

    private func handleBrandSelection(_ brand: Brand) {
        AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
            "screen": "SideMenu",
            "brand": brand.name
        ])

        bannerTarget = .brand(brand)
        showMenu = false
    }

    private func handleProfileTap() {
        AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
            "screen": "SideMenu",
            "destination": "profile"
        ])

        bannerTarget = .profile
        showMenu = false
    }

    private func handleSettingsTap() {
        AnalyticsManager.shared.logCustomEvent(name: "side_menu_nav", params: [
            "screen": "SideMenu",
            "destination": "settings"
        ])

        bannerTarget = .settings
        showMenu = false
    }
}


enum BannerNavigationTarget: Hashable, Equatable {
    case brand(Brand)
    case category(String)
    case subcategory(String)
    case authRequired
    case booking
    case favorites
    case cart
    case profile
    case settings  // ✅ NEW
    case home

    static func == (lhs: BannerNavigationTarget, rhs: BannerNavigationTarget) -> Bool {
        switch (lhs, rhs) {
        case (.brand(let a), .brand(let b)): return a.id == b.id
        case (.category(let a), .category(let b)): return a == b
        case (.subcategory(let a), .subcategory(let b)): return a == b
        case (.booking, .booking), (.favorites, .favorites), (.cart, .cart),
             (.profile, .profile), (.settings, .settings), (.home, .home):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .brand(let brand):
            hasher.combine("brand")
            hasher.combine(brand.id)
        case .category(let category):
            hasher.combine("category")
            hasher.combine(category)
        case .subcategory(let sub):
            hasher.combine("subcategory")
            hasher.combine(sub)
        case .authRequired:
            AuthenticationView(showSignInView: .constant(true))
        case .booking:
            hasher.combine("booking")
        case .favorites:
            hasher.combine("favorites")
        case .cart:
            hasher.combine("cart")
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        case .home:
            hasher.combine("home")
        }
    }
}
