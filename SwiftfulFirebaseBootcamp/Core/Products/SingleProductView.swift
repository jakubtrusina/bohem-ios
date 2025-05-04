import SwiftUI
import Kingfisher
import FirebaseFirestore

struct SingleProductView: View {
    let productId: String
    @StateObject private var vm: ProductsViewModel = ProductsViewModel.shared

    @State private var selectedImageUrl: String?
    @State private var selectedBrand: Brand? = nil
    @State private var selectedSize: String = ""
    @State private var quantity: Int = 1
    @State private var cartAdded = false
    @State private var isFavorited = false
    @State private var product: Product?
    @State private var loadedBrand: Brand?
    @State private var relatedProducts: [Product] = []
    @State private var similarProducts: [Product] = []

    var body: some View {
        Group {
            if let product = product {
                productScrollView(product)
            } else {
                ProgressView("Loading product...")
            }
        }
        .task { await loadProductIfNeeded() }
    }

    private func loadProductIfNeeded() async {
        if let cached = vm.allProducts.first(where: { $0.id == productId }) {
            await setupProductData(product: cached)
        } else {
            do {
                let snapshot = try await Firestore.firestore().collection("products").document(productId).getDocument()
                if let loaded = try? snapshot.data(as: Product.self) {
                    await setupProductData(product: loaded)
                }
            } catch {
                print("❌ Failed to load product: \(error)")
            }
        }
    }

    private func setupProductData(product: Product) async {
        self.product = product
        self.selectedSize = product.sizes?.first?.size ?? ""
        self.selectedImageUrl = product.thumbnail
        self.cartAdded = false
        self.isFavorited = vm.favoriteProductIds.contains(product.id)
        await loadBrand(for: product)
        loadRelatedAndSimilarProducts(for: product)
    }

    private func loadRelatedAndSimilarProducts(for product: Product) {
        relatedProducts = vm.allProducts.filter { product.relatedProductIds?.contains($0.id) == true }
        similarProducts = vm.allProducts.filter { product.similarProducts?.contains($0.id) == true }
    }

    private func loadBrand(for product: Product) async {
        guard let brandName = product.brand else { return }
        do {
            self.loadedBrand = try await BrandManager.shared.getBrandByName(brandName)
        } catch {
            print("❌ Failed to load brand info: \(error.localizedDescription)")
        }
    }

    private func labeledAttribute(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.body).foregroundColor(.primary)
        }
    }

    private func productScrollView(_ product: Product) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                topImageSection(for: product)
                imageCarousel(for: product)
                productDetailsSection(for: product)
                sizeQuantitySection(for: product)
                attributesSection(for: product)

                if !similarProducts.isEmpty {
                    ProductSliderScrollView(
                        products: similarProducts,
                        favoriteProductIds: vm.favoriteProductIds,
                        cartAddedProductId: CartManager.shared.cartItems.first?.product.id,
                        onTap: { selected in Task { await setupProductData(product: selected) } },
                        onToggleFavorite: toggleFavorite,
                        onAddToCart: quickAddToCart
                    )
                }

                if !relatedProducts.isEmpty {
                    ProductSliderScrollView(
                        products: relatedProducts,
                        favoriteProductIds: vm.favoriteProductIds,
                        cartAddedProductId: CartManager.shared.cartItems.first?.product.id,
                        onTap: { selected in Task { await setupProductData(product: selected) } },
                        onToggleFavorite: toggleFavorite,
                        onAddToCart: quickAddToCart
                    )
                }

                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) { addToCartButton(for: product) }
        .sheet(item: $selectedBrand) { brand in
            BrandView(brand: brand)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": "SingleProductView",
                "item_id": product.id,
                "item_name": product.title ?? "Unknown"
            ])
        }
    }

    private func toggleFavorite(product: Product) {
        Task {
            let user = try? AuthenticationManager.shared.getAuthenticatedUser()
            if let user {
                if vm.favoriteProductIds.contains(product.id) {
                    try? await UserManager.shared.removeUserFavoriteProductByProductId(userId: user.uid, productId: product.id)
                } else {
                    try? await UserManager.shared.addUserFavoriteProduct(userId: user.uid, productId: product.id)
                }
                await vm.loadFavoriteProductIds()
            }
        }
    }

    private func quickAddToCart(product: Product) {
        Task {
            await CartManager.shared.addToCart(product: product, size: product.sizes?.first?.size ?? "", quantity: 1)
        }
    }

    private func topImageSection(for product: Product) -> some View {
        ZStack(alignment: .topTrailing) {
            KFImage(URL(string: selectedImageUrl ?? product.thumbnail ?? ""))
                .resizable()
                .cancelOnDisappear(true)
                .fade(duration: 0.25)
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color.white)

            Button {
                toggleFavorite(product: product)
                withAnimation { isFavorited.toggle() }
            } label: {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding(12)
            }
        }
    }

    private func imageCarousel(for product: Product) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(product.images ?? [], id: \ .self) { urlString in
                    if let url = URL(string: urlString) {
                        KFImage(url)
                            .resizable()
                            .cancelOnDisappear(true)
                            .fade(duration: 0.25)
                            .scaledToFill()
                            .frame(width: 80, height: 100)
                            .clipped()
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(urlString == selectedImageUrl ? Color.black : Color.clear, lineWidth: 2))
                            .onTapGesture { selectedImageUrl = urlString }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private func productDetailsSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.title ?? "Unnamed")
                .font(.title2)
                .fontWeight(.semibold)

            if let brand = product.brand, let loadedBrand = loadedBrand, let logoUrl = loadedBrand.logoUrl, let url = URL(string: logoUrl) {
                Button { selectedBrand = loadedBrand } label: {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 120, maxHeight: 40)
                        .padding(.vertical, 4)
                }
            }

            if let price = product.price {
                Text("\(price) CZK")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            if let category = product.category {
                Text("Category: \(category.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider().padding(.vertical, 8)

            if let desc = product.description?[Locale.current.languageCode ?? "en"] ?? product.description?["en"] {
                Text(desc).font(.body)
            }
        }
        .padding()
    }

    private func sizeQuantitySection(for product: Product) -> some View {
        VStack(spacing: 16) {
            if let sizes = product.sizes, !sizes.isEmpty {
                VStack(alignment: .leading) {
                    Text("Select Size").font(.subheadline)
                    Picker("Size", selection: $selectedSize) {
                        ForEach(sizes, id: \.size) { entry in
                            Text("\(entry.size) (\(entry.stock) left)").tag(entry.size)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            } else {
                Text("No sizes available").foregroundColor(.gray).italic()
            }

            if let selectedStock = product.sizes?.first(where: { $0.size == selectedSize })?.stock {
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...selectedStock)
            } else {
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    private func attributesSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let material = product.material { labeledAttribute("Material", material) }
            if let fit = product.fit { labeledAttribute("Fit", fit) }
            if let care = product.care { labeledAttribute("Care Instructions", care) }
            if let colors = product.colors, !colors.isEmpty {
                labeledAttribute("Available Colors", colors.joined(separator: ", "))
            }
            if let model = product.model {
                if let height = model.height_cm { labeledAttribute("Model Height", "\(height) cm") }
                if let wearing = model.wearing_size { labeledAttribute("Model Wearing", wearing) }
            }
            if let note = product.designerNote { labeledAttribute("Designer Note", note) }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    private func addToCartButton(for product: Product) -> some View {
        VStack {
            Divider()
            Button {
                Task {
                    await CartManager.shared.addToCart(product: product, size: selectedSize, quantity: quantity)
                    withAnimation { cartAdded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { cartAdded = false }
                }
            } label: {
                Text(cartAdded ? "Added to Cart" : "Add to Cart")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .background(.ultraThinMaterial)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
