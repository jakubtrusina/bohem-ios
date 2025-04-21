import SwiftUI

struct ProductsView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @State private var favoriteProductIds: Set<Int> = []
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false
    @State private var cartAddedProductId: Int? = nil
    @State private var favoriteAddedProductId: Int? = nil
    
    let mainCategories = ["Dámské Oblečení", "Dámské Plavky", "Doplňky"]
    let subcategories: [String: [String]] = [
        "Dámské Oblečení": ["Vše", "Šaty", "Dámská Trička", "Dámské Kardigany", "Sukně", "Mikiny", "Kalhoty", "Trenčkoty"],
        "Dámské Plavky": ["Vše", "Jednodílné"],
        "Doplňky": ["Vše", "Tašky", "Náhrdelníky", "Náramky", "Náušnice"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Top Category Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(mainCategories, id: \.self) { main in
                        Button {
                            viewModel.selectedMainCategory = main
                            viewModel.filterProducts(for: nil)
                        } label: {
                            Text(main)
                                .fontWeight(viewModel.selectedMainCategory == main ? .bold : .regular)
                                .foregroundColor(viewModel.selectedMainCategory == main ? .black : .gray)
                                .underline(viewModel.selectedMainCategory == main, color: .black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // MARK: - Subcategory Bar
            if let subList = subcategories[viewModel.selectedMainCategory] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subList, id: \.self) { sub in
                            Button {
                                viewModel.filterProducts(for: sub == "Vše" ? nil : sub)
                            } label: {
                                Text(sub)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedSubcategory == sub ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(viewModel.selectedSubcategory == sub ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            
            // MARK: - Products
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(viewModel.filteredProducts) { product in
                        buildProductCard(for: product)
                        
                        if product == viewModel.filteredProducts.last {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    viewModel.getProducts()
                                }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Products")
        .toolbar { buildToolbar() }
        .onAppear {
            let screenName = String(describing: Self.self)

            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": screenName
            ])

            viewModel.getProducts()
            viewModel.loadFavoriteProductIds()
            favoriteProductIds = viewModel.favoriteProductIds
        }

        .navigationDestination(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(product: product)
            }
        }
    }
    
    private func buildProductCard(for product: Product) -> some View {
        OverlayProductCardView(
            product: product,
            isFavorited: favoriteProductIds.contains(product.id),
            isCartAdded: cartAddedProductId == product.id,
            onTap: {
                selectedProduct = product
                isShowingDetail = true
            },
            onToggleFavorite: {
                Task {
                    favoriteProductIds = await viewModel.toggleFavoriteProduct(
                        productId: product.id,
                        currentFavorites: favoriteProductIds
                    )
                    withAnimation {
                        favoriteAddedProductId = product.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        favoriteAddedProductId = nil
                    }
                }
            },
            onAddToCart: {
                Task {
                    await CartManager.shared.addToCart(product: product, size: "M", quantity: 1)
                    withAnimation {
                        cartAddedProductId = product.id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cartAddedProductId = nil
                    }
                }
            }
        )
    }
    
    func uploadLocalJSONToFirestore() {
        guard let url = Bundle.main.url(forResource: "firestore_products_fixed", withExtension: "json") else {
            print("❌ Could not find local JSON file.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([String: Product].self, from: data)

            Task {
                for (_, product) in decoded {
                    do {
                        try await ProductsManager.shared.uploadProduct(product: product)
                        print("✅ Uploaded: \(product.title ?? "")")
                    } catch {
                        print("❌ Failed to upload \(product.title ?? ""): \(error)")
                    }
                }
            }
        } catch {
            print("❌ Error loading JSON: \(error)")
        }
    }


    
    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu("Filter: \(viewModel.selectedFilter?.rawValue ?? "NONE")") {
                ForEach(ProductsViewModel.FilterOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        Task {
                            try? await viewModel.filterSelected(option: option)
                        }
                    }
                }
            }
        }
    }
}
