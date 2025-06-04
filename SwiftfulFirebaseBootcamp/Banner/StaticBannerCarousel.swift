import SwiftUI
import Kingfisher
import FirebaseFirestore

struct StaticBannerCarousel: View {
    @StateObject private var vm = BannerViewModel()
    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var brandId: String?

    var body: some View {
        let filtered = vm.bannersByBrand[brandId ?? ""] ?? []

        return Group {
            if filtered.isEmpty {
                ProgressView("Načítání bannerů...")
                    .frame(height: 300)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(filtered.indices, id: \.self) { index in
                        staticBannerSlide(banner: filtered[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 320)
                .onReceive(timer) { _ in
                    withAnimation {
                        currentIndex = (currentIndex + 1) % filtered.count
                    }
                }
            }
        }
        .onAppear {
            Task {
                if !vm.prefetchedBrands.contains(brandId ?? "") {
                    await vm.fetchBanners(for: brandId)
                }
            }
        }
    }

    @ViewBuilder
    private func staticBannerSlide(banner: Banner) -> some View {
        ZStack {
            KFImage(URL(string: banner.imageUrl))
                .resizable()
                .placeholder {
                    Color.gray.opacity(0.1).overlay(ProgressView())
                }
                .cancelOnDisappear(true)
                .scaledToFill()
                .frame(height: 320)
                .clipped()

            VStack(spacing: 12) {
                Spacer()
                VStack(spacing: 6) {
                    Text(banner.title)
                        .font(.title).bold()
                        .foregroundColor(.white)

                    Text(banner.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.5), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}
