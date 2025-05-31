//import SwiftUI
//
//struct MainTryOnViewMeta: View {
//    @State private var showProducts = false
//    @State private var showFavorites = false
//    @State private var showCart = false
//    @State private var showProfile = false
//    @State private var activeCategory: String? = nil
//    @Binding var showSignInView: Bool
//    @StateObject private var profileViewModel = ProfileViewModel()
//
//    // ✅ no need to call productsVM.getProducts() again here
//    @StateObject private var productsVM = ProductsViewModel.shared
//
//    var body: some View {
//        AnalyticsTrackedView(screen: "MainTryOnView") {
//            VStack(spacing: 0) {
//                // 🔝 Top bar
//                HStack {
//                    Spacer()
//                    HStack(spacing: 16) {
//                        topButton(icon: "cart") { showProducts.toggle() }
//                        topButton(icon: "heart") { showFavorites.toggle() }
//                        topButton(icon: "bag") { showCart.toggle() }
//                        topButton(icon: "person") { showProfile.toggle() }
//                    }
//                    .padding(.top, 20)
//                    .padding(.trailing, 20)
//                }
//                ProductSliderView()
//                    .frame(maxHeight: .infinity, alignment: .bottom)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(
//                ZStack {
//                    Image("BackgroundImage")
//                        .resizable()
//                        .scaledToFill()
//                        .ignoresSafeArea()
//
//                    Color.black.opacity(0.4)
//                        .ignoresSafeArea()
//
//                    VStack {
//                        Spacer(minLength: 100)
//
//                        Text("Připravujeme revoluční 3D zážitek z virtuálního zkoušení oblečení.")
//                            .font(.system(size: 22, weight: .heavy))
//                            .foregroundColor(.white.opacity(0.25))
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 30)
//
//                        Spacer()
//                    }
//                }
//            )
//            .sheet(isPresented: $showProducts) {
//                NavigationStack { ProductsView() }
//            }
//            .sheet(isPresented: $showFavorites) {
//                NavigationStack { FavoriteView() }
//            }
//            .sheet(isPresented: $showCart) {
//                NavigationStack { CartView() }
//            }
//            .sheet(isPresented: $showProfile) {
//                NavigationStack { ProfileView(showSignInView: $showSignInView) }
//            }
//            .onAppear {
//                Task {
//                    try? await profileViewModel.loadCurrentUser()
//                    AnalyticsManager.shared.logEvent(.screenView, params: [
//                        "screen_name": String(describing: Self.self)
//                    ])
//                }
//            }
//        }
//    }
//
//    private func topButton(icon: String, action: @escaping () -> Void) -> some View {
//        Button(action: action) {
//            Image(systemName: icon)
//                .font(.system(size: 20, weight: .medium))
//                .foregroundColor(.black)
//                .padding(10)
//                .background(Color.white.opacity(0.8))
//                .clipShape(Circle())
//                .shadow(radius: 3)
//        }
//    }
//}
