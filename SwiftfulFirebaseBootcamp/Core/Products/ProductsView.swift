import SwiftUI
import FirebaseFirestore

struct ProductsView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @ObservedObject private var vm = ProductsViewModel.shared
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false
    @State private var cartAddedProductId: String? = nil
    @State private var didLoad = false
    @State private var isShowingFilters = false
    @Binding var bannerTarget: BannerNavigationTarget?
    @Binding var showMenu: Bool
    let dismiss: DismissAction

    var selectedMainCategory: String? = nil
    var selectedSubcategory: String? = nil

    let mainCategories: [String] = [
        "Dámské Oblečení",
        "Dámské Plavky",
        "Doplňky"
    ]

    let subcategories: [String: [String]] = [
        "Dámské Oblečení": ["Šaty", "Dámská Trička", "Kabát", "Kalhoty", "Mikiny", "Sukně"],
        "Dámské Plavky": ["Jednodílné", "Horní díl", "Spodní díl"],
        "Doplňky": ["Náhrdelníky", "Náramky", "Náušnice", "Pásky", "Prstýnky", "Tašky"]
    ]

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                Color.clear.frame(height: 0).id("top") // anchor for scroll-to-top

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
                    .padding(.bottom, 12)
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

                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation {
                            isShowingFilters.toggle()
                        }
                    }) {
                        Label("Filtry", systemImage: isShowingFilters ? "chevron.up" : "chevron.down")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }

                    if viewModel.selectedFilter != nil ||
                        viewModel.selectedSubcategory != nil ||
                        !viewModel.selectedColors.isEmpty ||
                        !viewModel.selectedSizes.isEmpty ||
                        !viewModel.selectedBrands.isEmpty ||
                        viewModel.selectedPriceRange != nil ||
                        viewModel.showNewArrivalsOnly {
                        Button(action: {
                            viewModel.resetFilters()
                            viewModel.selectedSubcategory = nil
                            viewModel.getProducts()
                        }) {
                            Text("Resetovat")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.black)
                                .cornerRadius(16)
                        }
                        .transition(.opacity)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                if isShowingFilters {
                    ProductFiltersView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                ScrollView {
                    LazyVStack(spacing: 24) {
                        productList()
                    }
                    .padding()
                }
            }
            .onAppear {
                print("[DEBUG] ProductsView .onAppear triggered")

                if let sub = selectedSubcategory {
                    print("[DEBUG] .onAppear detected selectedSubcategory: \(sub)")
                    viewModel.selectedSubcategory = sub

                    if let parent = viewModel.inferMainCategory(for: sub, from: subcategories) {
                        print("[DEBUG] .onAppear inferred main category: \(parent)")
                        viewModel.selectedMainCategory = parent
                    }

                    viewModel.getProducts()
                    viewModel.filterProducts(for: sub)
                } else if let main = selectedMainCategory {
                    print("[DEBUG] .onAppear detected selectedMainCategory: \(main)")
                    viewModel.selectedMainCategory = main
                    viewModel.selectedSubcategory = nil
                    viewModel.getProducts()
                    viewModel.filterProducts(for: nil)
                }

                if !didLoad {
                    didLoad = true
                    AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": String(describing: Self.self)])
                    viewModel.loadBrands()
                    viewModel.loadFavoriteProductIds()
                }
            }



            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $isShowingDetail) {
                if let product = selectedProduct {
                    SingleProductView(productId: product.id)
                }
            }
            .onChange(of: bannerTarget) { newTarget in
                guard let target = newTarget else { return }
                print("[DEBUG] ProductsView bannerTarget changed to: \(target)")

                switch target {
                case .subcategory(let sub):
                    print("[DEBUG] Switching to subcategory: \(sub)")

                    if let main = mainCategories.first(where: {
                        subcategories[$0]?.contains(sub) == true }) {
                        print("[DEBUG] Parent category for subcategory '\(sub)' is '\(main)'")

                        viewModel.selectedMainCategory = main
                        viewModel.selectedSubcategory = sub
                        viewModel.getProducts()
                        viewModel.filterProducts(for: sub)
                    }
                case .category(let main):
                    print("[DEBUG] Switching to category: \(main)")
                    viewModel.selectedMainCategory = main
                    viewModel.selectedSubcategory = nil
                    viewModel.getProducts()
                    viewModel.filterProducts(for: nil)
                default:
                    break
                }

                DispatchQueue.main.async {
                    bannerTarget = nil
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func productList() -> some View {
        if viewModel.filteredProducts.isEmpty {
            Text("Žádné produkty nebyly nalezeny.")
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

    @ViewBuilder
    private var filterSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Color.clear.frame(height: 0).id("top")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowingFilters = false
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Zpět")
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Image("LOGO")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

        private func buildProductCard(for product: Product) -> some View {
            let id = product.id

            return OverlayProductCardView(
                product: product,
                isFavorited: vm.favoriteProductIds.contains(id),
                isCartAdded: cartAddedProductId == id,
                onTap: {
                    selectedProduct = product
                    isShowingDetail = true
                },
                onToggleFavorite: {
                    Task {
                        let updated = await vm.toggleFavoriteProduct(productId: product.id, currentFavorites: vm.favoriteProductIds)
                        await MainActor.run {
                            vm.favoriteProductIds = updated
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
