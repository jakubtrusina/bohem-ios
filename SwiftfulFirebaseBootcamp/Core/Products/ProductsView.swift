import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ProductsView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @State private var favoriteProductIds: Set<String> = []
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false
    @State private var cartAddedProductId: String? = nil
    @State private var favoriteAddedProductId: String? = nil
    @State private var didLoad = false
    @State private var isShowingFilters = false

    let mainCategories: [String] = [
        "Dámské Oblečení",
        "Dámské Plavky",
        "Doplňky"
    ]

    let subcategories: [String: [String]] = [
        "Dámské Oblečení": [
            "Šaty",
            "Dámská Trička",
            "Kabát",        // Treated as standalone subcategory now
            "Kalhoty",
            "Mikiny",
            "Sukně"
        ],
        "Dámské Plavky": [
            "Jednodílné",
            "Horní díl",
            "Spodní díl"
        ],
        "Doplňky": [
            "Náhrdelníky",
            "Náramky",
            "Náušnice",
            "Pásky",
            "Prstýnky",
            "Tašky"
        ]
    ]


    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Produkty")
                    .font(.largeTitle.bold())
                    .padding(.leading)
                Spacer()
                if viewModel.selectedFilter != nil || viewModel.selectedSubcategory != nil || !viewModel.selectedColors.isEmpty || !viewModel.selectedSizes.isEmpty || !viewModel.selectedBrands.isEmpty || viewModel.selectedPriceRange != nil || viewModel.showNewArrivalsOnly {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                    .foregroundColor(.red)
                    .padding(.trailing, 4)
                }
                Button(action: {
                    isShowingFilters = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.black)
                }
                .padding(.trailing)
            }
            .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(mainCategories, id: \.self) { main in
                        let isSelected = viewModel.selectedMainCategory == main
                        Button(action: {
                            viewModel.selectedMainCategory = main
                            viewModel.selectedSubcategory = nil
                            viewModel.getProducts()
                        }) {
                            Text(main)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? .black : .gray)
                                .underline(isSelected, color: .black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }

            if let subList = subcategories[viewModel.selectedMainCategory] {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subList, id: \.self) { sub in
                            let isSelected = viewModel.selectedSubcategory == sub
                            Button(action: {
                                viewModel.filterProducts(for: sub == "Vše" ? nil : sub)
                            }) {
                                Text(sub)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(isSelected ? .white : .black)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }

            ScrollView {
                LazyVStack(spacing: 24) {
                    productList()
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            guard !didLoad else { return }
            didLoad = true

            let screenName = String(describing: Self.self)
            AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": screenName])

            viewModel.getProducts()
            viewModel.loadFavoriteProductIds()
            favoriteProductIds = viewModel.favoriteProductIds
        }
        .navigationDestination(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(productId: product.id)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollView {
                        ProductFiltersView(viewModel: viewModel)

                        Divider().padding(.vertical)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Řazení podle ceny")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(ProductsViewModel.FilterOption.allCases, id: \.self) { option in
                                Button(action: {
                                    Task {
                                        try? await viewModel.filterSelected(option: option)
                                    }
                                }) {
                                    HStack {
                                        Text(option.rawValue.capitalized)
                                        if viewModel.selectedFilter == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .padding(.top)
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.resetFilters()
                        isShowingFilters = false
                    } label: {
                        Text("Resetovat filtry")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding()
                    }
                }
                .navigationTitle("Filtry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Zavřít") {
                            isShowingFilters = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func productList() -> some View {
        if viewModel.filteredProducts.isEmpty {
            Text("No products found.")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 40)
        } else {
            ForEach(viewModel.filteredProducts) { product in
                buildProductCard(for: product)

                if product == viewModel.filteredProducts.last {
                    ProgressView()
                        .padding()
                        .onAppear {
                            if viewModel.lastDocument != nil {
                                viewModel.getProducts()
                            }
                        }
                }
            }
        }
    }

    private func buildProductCard(for product: Product) -> some View {
        let id = product.id

        return OverlayProductCardView(
            product: product,
            isFavorited: favoriteProductIds.contains(id),
            isCartAdded: cartAddedProductId == id,
            onTap: {
                selectedProduct = product
                isShowingDetail = true
            },
            onToggleFavorite: {
                Task {
                    favoriteProductIds = await viewModel.toggleFavoriteProduct(
                        productId: id,
                        currentFavorites: favoriteProductIds
                    )
                    withAnimation {
                        favoriteAddedProductId = id
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
                        cartAddedProductId = id
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cartAddedProductId = nil
                    }
                }
            }
        )
    }
}
