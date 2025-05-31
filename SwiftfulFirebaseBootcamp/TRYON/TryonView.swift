import SwiftUI
import AVKit
import FirebaseStorage
import Foundation

struct MainTryOnView: View {
    @State private var showMenu = false
    @State private var expandedCategory: String? = nil
    @Binding var showSignInView: Bool
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var productsVM = ProductsViewModel.shared
    @Binding var bannerTarget: BannerNavigationTarget?
    @Environment(\.dismiss) var dismiss
    @State private var appearTime: Date?

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0){
                contentArea
            }
            .navigationBarBackButtonHidden(true)
            .animation(.easeInOut, value: showMenu)
            .onAppear {
                appearTime = Date()
                AnalyticsManager.shared.logEvent(.screenView, params: [
                    "screen_name": "MainTryOnView"
                ])

                AnalyticsManager.shared.logCustomEvent(name: "banner_viewed", params: [
                    "screen": "MainTryOnView", "banner_id": "oneMain"
                ])
                AnalyticsManager.shared.logCustomEvent(name: "banner_viewed", params: [
                    "screen": "MainTryOnView", "banner_id": "secondMain"
                ])
                AnalyticsManager.shared.logCustomEvent(name: "section_viewed", params: [
                    "screen": "MainTryOnView", "section_id": "TryonShowroom"
                ])

                Task {
                    async let profileTask = try? profileViewModel.loadCurrentUser()
                    async let bannerPrefetch = BannerViewModel.shared.prefetch(for: ["oneMain", "secondMain"])
                    async let sliderPrefetch = SliderPrefetcher.shared.prefetch(sliders: ["mainProductSlider", "Šaty"])
                    _ = await (profileTask, bannerPrefetch, sliderPrefetch)
                }
            }
            .onDisappear {
                if let start = appearTime {
                    let duration = Date().timeIntervalSince(start)
                    AnalyticsManager.shared.logCustomEvent(name: "screen_time", params: [
                        "screen_name": "MainTryOnView",
                        "duration_seconds": duration
                    ])
                }
            }
        }
    }

    var contentArea: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 🩱 First Banner + Swimwear Highlight
                DynamicBannerCarousel(brandId: "oneMain", bannerTarget: $bannerTarget)

                Text("Objevte naši exkluzivní kolekci plavek")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("Prémiový mikrovlákenný materiál s příměsí lycry pro maximální pohodlí a styl.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                DynamicProductSlider(sliderId: "mainProductSlider")
                    .frame(maxWidth: .infinity)

                // 👗 Second Banner + Dresses Highlight
                DynamicBannerCarousel(brandId: "secondMain", bannerTarget: $bannerTarget)

                Text("Letní šaty navržené pro ženy, které milují eleganci a pohodlí.")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Text("Lehké materiály, sofistikované střihy a jedinečné vzory — vše v jedné kolekci.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 16)

                DynamicProductSlider(sliderId: "Šaty")
                    .frame(maxWidth: .infinity)

                // 🛍️ Showroom Booking CTA
                TryonShowroomSection(bannerTarget: $bannerTarget)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
