//
//  Banners.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/20/25.
//

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
    var brandId: String? // Used for filtering
}

// MARK: - Banner ViewModel
class BannerViewModel: ObservableObject {
    @Published var banners: [Banner] = []
    private var db = Firestore.firestore()

    static let shared = BannerViewModel()

    // Preload banners for specific brandIds
    func prefetch(for brandIds: [String]) async {
        var allBanners: [Banner] = []

        for brandId in brandIds {
            do {
                let snapshot = try await db.collection("banners")
                    .whereField("brandId", isEqualTo: brandId)
                    .order(by: "order")
                    .getDocuments()

                let fetched = snapshot.documents.compactMap { try? $0.data(as: Banner.self) }
                allBanners.append(contentsOf: fetched)
                print("✅ Prefetched banners for brand: \(brandId)")
            } catch {
                print("❌ Failed to fetch banners for \(brandId): \(error.localizedDescription)")
            }
        }

        await MainActor.run {
            self.banners = allBanners
        }
    }

    // Fallback fetch (if not prefetched)
    func fetchBanners(for brandId: String?) async {
        var query: Query = db.collection("banners").order(by: "order")
        if let brandId = brandId {
            query = query.whereField("brandId", isEqualTo: brandId)
        }

        do {
            let snapshot = try await query.getDocuments()
            self.banners = snapshot.documents.compactMap { try? $0.data(as: Banner.self) }
            print("✅ Fetched \(self.banners.count) banners")
        } catch {
            print("❌ Error fetching banners: \(error.localizedDescription)")
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
        Group {
            if vm.banners.isEmpty {
                ProgressView("Načítání bannerů...")
                    .frame(height: 300)
            } else {
                let filtered = vm.banners.filter { $0.brandId == brandId }
                
                if filtered.isEmpty {
                    EmptyView()
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(filtered.indices, id: \.self) { index in
                            bannerSlide(banner: filtered[index])
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
        }
        .onAppear {
            Task {
                if vm.banners.filter({ $0.brandId == brandId }).isEmpty {
                    await vm.fetchBanners(for: brandId)
                }
            }
        }
    }

    // MARK: - Banner Slide View
    @ViewBuilder
    private func bannerSlide(banner: Banner) -> some View {
        ZStack {
            AsyncImage(url: URL(string: banner.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.1).overlay(ProgressView())
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.red.opacity(0.2).overlay(Text("❌ Chyba obrázku"))
                @unknown default:
                    EmptyView()
                }
            }
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
                            bannerTarget = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                bannerTarget = target
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
                            print("⚠️ Unknown destination: \(destination)")
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
