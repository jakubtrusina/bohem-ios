import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct BrandView: View {
    let brandName: String
    @State private var brand: Brand?
    @State private var products: [Product] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading brand info...")
                    .padding(.top, 40)
            } else if let brand = brand {
                VStack(spacing: 16) {
                    if let logoUrl = brand.logoUrl, let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 60)
                        } placeholder: {
                            ProgressView()
                        }
                    }

                    Text(brand.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(brand.description ?? "No description available.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Brand Products
                LazyVStack(spacing: 24) {
                    ForEach(products, id: \.id) { product in
                        OverlayProductCardView(
                            product: product,
                            isFavorited: false,
                            isCartAdded: false,
                            onTap: {},
                            onToggleFavorite: {},
                            onAddToCart: {}
                        )
                    }
                }
                .padding()
            } else {
                Text("⚠️ Brand not found.")
                    .padding()
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(brand?.name ?? brandName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        await loadBrand()
        await loadProducts()
        isLoading = false
    }

    private func loadBrand() async {
        print("🔍 Looking for brand named: \(brandName)")
        do {
            brand = try await BrandManager.shared.getBrandByName(brandName)
            if let brand = brand {
                print("✅ Brand loaded: \(brand.name)")
            } else {
                print("❌ Brand not found for: \(brandName)")
            }
        } catch {
            print("🔥 Failed to load brand: \(error.localizedDescription)")
        }
    }

    private func loadProducts() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("products")
                .whereField("brand", isEqualTo: brandName)
                .getDocuments()
            products = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
        } catch {
            print("🔥 Failed to load products for brand: \(error.localizedDescription)")
        }
    }
}
