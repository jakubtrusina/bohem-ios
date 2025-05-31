import SwiftUI
import Kingfisher
import FirebaseFirestore

struct SingleProductView: View {
    let productId: String
    @StateObject private var vm: ProductsViewModel = ProductsViewModel.shared

    @State private var selectedImageUrl: String?
    @State private var selectedBrand: Brand?
    @State private var selectedSize: String = ""
    @State private var quantity: Int = 1
    @State private var cartAdded = false
    @State private var product: Product?
    @State private var loadedBrand: Brand?
    @State private var relatedProducts: [Product] = []
    @State private var similarProducts: [Product] = []
    @State private var showingSizeGuide = false
    @State private var showSizeSheet = false
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        Group {
            if let product = product {
                productScrollView(product)
            } else {
                ProgressView("Načítám produkt...")
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
                print("❌ Nepodařilo se načíst produkt: \(error)")
            }
        }
    }

    private func setupProductData(product: Product) async {
        self.product = product
        self.selectedSize = product.sizes?.first?.size ?? ""
        self.selectedImageUrl = product.thumbnail
        self.cartAdded = false
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
            print("❌ Nepodařilo se načíst značku: \(error.localizedDescription)")
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
                    Text("Podobné produkty")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ProductSliderScrollView(
                        products: similarProducts,
                        favoriteProductIds: vm.favoriteProductIds,
                        cartAddedProductIds: Set(CartManager.shared.cartItems.map { $0.product.id }),
                        onTap: { selected in Task { await setupProductData(product: selected) } },
                        onToggleFavorite: toggleFavorite,
                        onAddToCart: quickAddToCart
                    )
                    .padding(.bottom)
                }
                
                if !relatedProducts.isEmpty {
                    Text("Související produkty")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ProductSliderScrollView(
                        products: relatedProducts,
                        favoriteProductIds: vm.favoriteProductIds,
                        cartAddedProductIds: Set(CartManager.shared.cartItems.map { $0.product.id }),
                        onTap: { selected in Task { await setupProductData(product: selected) } },
                        onToggleFavorite: toggleFavorite,
                        onAddToCart: quickAddToCart
                    )
                    .padding(.bottom)
                }
                
                Spacer(minLength: 80)
            }
        }
        .safeAreaInset(edge: .bottom) { addToCartButton(for: product) }
        .sheet(isPresented: Binding(
            get: { selectedBrand != nil },
            set: { newValue in if !newValue { selectedBrand = nil } }
        )) {
            if let brand = selectedBrand {
                NavigationStack {
                    BrandView(
                        brand: brand,
                        bannerTarget: .constant(nil),
                        showMenu: .constant(false)
                    )
                }
            }
        }

        .sheet(isPresented: $showingSizeGuide) {
            NavigationView {
                SizeGuideView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zpět")
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": "SingleProductView",
                "item_id": product.id,
                "item_name": product.title ?? "Neznámý"
            ])
        }
    }
        
    private func toggleFavorite(product: Product) {
        Task {
            let updated = await vm.toggleFavoriteProduct(productId: product.id, currentFavorites: vm.favoriteProductIds)
            await MainActor.run {
                vm.favoriteProductIds = updated
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
                } label: {
                    Image(systemName: vm.favoriteProductIds.contains(product.id) ? "heart.fill" : "heart")

                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(12)
                }
            }
        }
        
        private func imageCarousel(for product: Product) -> some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(product.images ?? [], id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .cancelOnDisappear(true)
                                .fade(duration: 0.25)
                                .scaledToFill()
                                .frame(width: 80, height: 100)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(urlString == selectedImageUrl ? Color.black : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedImageUrl = urlString
                                }
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
            Text(product.title ?? "Bez názvu")
                .font(.title2)
                .fontWeight(.semibold)

            if let brand = product.brand, let loadedBrand = loadedBrand, let logoUrl = loadedBrand.logoUrl, let url = URL(string: logoUrl) {
                Button {
                    selectedBrand = loadedBrand
                } label: {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 120, maxHeight: 40)
                        .padding(.vertical, 4)
                }
            }

            if let price = product.price {
                Text("\(price) Kč")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Divider().padding(.vertical, 8)

            if let desc = product.description?[Locale.current.languageCode ?? "cs"] ?? product.description?["en"] {
                Text(desc).font(.body)
            }
        }
        .padding()
    }

    private func sizeQuantitySection(for product: Product) -> some View {
        VStack(spacing: 16) {
            if let sizes = product.sizes, !sizes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Vyberte velikost")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Button(action: {
                            showingSizeGuide = true
                        }) {
                            Text("Průvodce velikostí")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .underline()
                        }
                    }

                    Picker(selection: $selectedSize, label: Text("")) {
                        ForEach(sizes, id: \.size) { entry in
                            Text("\(entry.size) (\(entry.stock) ks skladem)").tag(entry.size)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } else {
                Text("Velikosti nejsou dostupné")
                    .foregroundColor(.gray)
                    .italic()
            }

            if let stock = product.sizes?.first(where: { $0.size == selectedSize })?.stock {
                Stepper("Množství: \(quantity)", value: $quantity, in: 1...stock)
            } else {
                Stepper("Množství: \(quantity)", value: $quantity, in: 1...10)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    private func attributesSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let material = product.material { labeledAttribute("Materiál", material) }
            if let fit = product.fit { labeledAttribute("Střih", fit) }
            if let care = product.care { labeledAttribute("Péče", care) }
            if let colors = product.colors, !colors.isEmpty {
                labeledAttribute("Dostupné barvy", colors.joined(separator: ", "))
            }
            if let model = product.model {
                if let height = model.height_cm {
                    labeledAttribute("Výška modelky", "\(height) cm")
                }
                if let wearing = model.wearing_size {
                    labeledAttribute("Velikost na modelce", wearing)
                }
            }
            if let note = product.designerNote {
                labeledAttribute("Poznámka designéra", note)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    private func labeledAttribute(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.body).foregroundColor(.primary)
        }
    }

    private func addToCartButton(for product: Product) -> some View {
        VStack {
            Divider()
            Button {
                Task {
                    await CartManager.shared.addToCart(product: product, size: selectedSize, quantity: quantity)
                    withAnimation { cartAdded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cartAdded = false
                    }
                }
            } label: {
                Text(cartAdded ? "Přidáno do košíku" : "Přidat do košíku")
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
