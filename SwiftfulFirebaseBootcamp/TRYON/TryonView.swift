import SwiftUI

struct MainTryOnView: View {
    @State private var showProducts = false
    @State private var showFavorites = false
    @State private var showCart = false
    @State private var showProfile = false
    @Binding var showSignInView: Bool
    @StateObject private var profileViewModel = ProfileViewModel()


    var body: some View {
        AnalyticsTrackedView(screen: "MainTryOnView") {
            ZStack {
                Avatar3DView()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        HStack(spacing: 16) {
                            topButton(icon: "cart") { showProducts.toggle() }
                            topButton(icon: "star.fill") { showFavorites.toggle() }
                            topButton(icon: "bag") { showCart.toggle() }
                            topButton(icon: "person") { showProfile.toggle() }
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                    }

                    Spacer()
                    ProductSliderView()
                        .padding(.bottom, 20)
                }

                .sheet(isPresented: $showProducts) {
                    NavigationStack { ProductsView() }
                }
                .sheet(isPresented: $showFavorites) {
                    NavigationStack { FavoriteView() }
                }
                .sheet(isPresented: $showCart) {
                    NavigationStack { CartView() }
                }
                .sheet(isPresented: $showProfile) {
                    NavigationStack { ProfileView(showSignInView: $showSignInView) }
                }
                
                .onAppear {
                    Task {
                        try? await profileViewModel.loadCurrentUser()
                    
                        let screenName = String(describing: Self.self)

                        AnalyticsManager.shared.logEvent(.screenView, params: [
                            "screen_name": screenName
                        ])
                    }
                }
            }
            
        }
    }

    private func topButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .padding(10)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
    }
}
