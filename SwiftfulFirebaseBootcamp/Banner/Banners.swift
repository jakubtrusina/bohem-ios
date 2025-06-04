import Kingfisher
import SwiftUI
import FirebaseFirestore

// MARK: - Banner Model
struct Banner: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var subtitle: String
    var imageUrl: String
    var order: Int
    var destination: String?
    var brandId: String?
}

// MARK: - Banner ViewModel
class BannerViewModel: ObservableObject {
    @Published var bannersByBrand: [String: [Banner]] = [:]
    @Published var prefetchedBrands: Set<String> = []

    private var db = Firestore.firestore()
    static let shared = BannerViewModel()

    func prefetch(for brandIds: [String]) async {
        for brandId in brandIds where !prefetchedBrands.contains(brandId) {
            do {
                let snapshot = try await db.collection("banners")
                    .whereField("brandId", isEqualTo: brandId)
                    .order(by: "order")
                    .getDocuments()

                let fetched = snapshot.documents.compactMap { try? $0.data(as: Banner.self) }

                await MainActor.run {
                    self.bannersByBrand[brandId] = fetched
                    self.prefetchedBrands.insert(brandId)
                }

                print("✅ Prefetched banners for brand: \(brandId)")
            } catch {
                print("Failed to fetch banners for \(brandId): \(error.localizedDescription)")
            }
        }
    }

    func fetchBanners(for brandId: String?) async {
        guard let brandId = brandId else { return }

        do {
            let snapshot = try await db.collection("banners")
                .whereField("brandId", isEqualTo: brandId)
                .order(by: "order")
                .getDocuments()

            let fetched = snapshot.documents.compactMap { try? $0.data(as: Banner.self) }

            await MainActor.run {
                self.bannersByBrand[brandId] = fetched
            }

            print("✅ Fetched \(fetched.count) banners for \(brandId)")
        } catch {
            print("Error fetching banners: \(error.localizedDescription)")
        }
    }
}

// MARK: - Dynamic Banner Carousel
struct DynamicBannerCarousel: View {
    @ObservedObject private var vm = BannerViewModel.shared
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var brandId: String?
    @Binding var bannerTarget: BannerNavigationTarget?

    var body: some View {
        let filtered = vm.bannersByBrand[brandId ?? ""] ?? []

        return Group {
            if filtered.isEmpty {
                ProgressView("Načítání bannerů...")
                    .frame(height: 300)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(filtered.indices, id: \.self) { index in
                        bannerSlide(banner: filtered[index], bannerTarget: $bannerTarget)
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
                if !BannerViewModel.shared.prefetchedBrands.contains(brandId ?? "") {
                    await BannerViewModel.shared.fetchBanners(for: brandId)
                }
            }
        }
    }

    // MARK: - Banner Slide View
    @ViewBuilder
    private func bannerSlide(banner: Banner, bannerTarget: Binding<BannerNavigationTarget?>) -> some View {
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

                Button("Prohlédnout") {
                    Task {
                        guard let destination = banner.destination else { return }

                        func navigate(_ target: BannerNavigationTarget) {
                            bannerTarget.wrappedValue = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                bannerTarget.wrappedValue = target
                            }
                        }

                        if destination.starts(with: "brand:"),
                           let brandName = destination.components(separatedBy: "brand:").last,
                           let brand = try? await BrandManager.shared.getBrandByName(brandName) {
                            navigate(.brand(brand))
                        } else if destination.starts(with: "category:"),
                                  let category = destination.components(separatedBy: "category:").last {
                            navigate(.category(category))
                        } else if destination == "booking" {
                            navigate(.booking)
                        } else if destination == "favorites" {
                            navigate(.favorites)
                        } else if destination == "cart" {
                            navigate(.cart)
                        } else if destination == "profile" {
                            navigate(.profile)
                        } else {
                            print(" Unknown destination: \(destination)")
                        }
                    }
                }
                .font(.headline)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(8)
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
