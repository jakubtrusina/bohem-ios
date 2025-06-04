import SwiftUI
import Kingfisher

struct BrandView: View {
    let brand: Brand?
    @ObservedObject var vm = ProductsViewModel.shared
    @Binding var bannerTarget: BannerNavigationTarget?
    @Binding var showMenu: Bool

    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail: Bool = false
    @State private var cartAddedProductId: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                bannerWithLogo()

                VStack(spacing: 16) {
                    brandHeader()
                    contactLinks()
                }
                .padding(.horizontal)

                if let story = brand?.story, !story.isEmpty {
                    brandStory(story)
                }

                brandProductsSection()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let brandName = brand?.name {
                vm.getProducts(forBrand: brandName)
            }
        }
        .navigationDestination(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(productId: product.id)
            }
        }
    }

    // MARK: - Banner with Logo
    private func bannerWithLogo() -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                if let urlString = brand?.bannerUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 220)
                }

                if let logoUrl = brand?.logoUrl, let logo = URL(string: logoUrl) {
                    KFImage(logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 4)
                        .offset(y: 50)
                }
            }

            Spacer().frame(height: 60)
        }
    }

    // MARK: - Header
    private func brandHeader() -> some View {
        VStack(spacing: 8) {
            Text(brand?.name ?? "Značka")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            if let description = brand?.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Contact Links
    private func contactLinks() -> some View {
        HStack(spacing: 24) {
            if let website = brand?.website, let url = URL(string: website) {
                Link(destination: url) { Image(systemName: "globe") }
            }
            if let instagram = brand?.instagram, let url = URL(string: formattedIG(instagram)) {
                Link(destination: url) { Image(systemName: "camera") }
            }
            if let email = brand?.email, let url = URL(string: "mailto:\(email)") {
                Link(destination: url) { Image(systemName: "envelope") }
            }
            if let phone = brand?.phone, let url = URL(string: "tel:\(phone)") {
                Link(destination: url) { Image(systemName: "phone") }
            }
        }
        .font(.title3)
        .foregroundColor(.black)
        .padding(.top, 8)
    }

    // MARK: - Brand Story
    private func brandStory(_ story: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Příběh značky")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            Text(story)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal)
        }
    }

    // MARK: - Product Section
    @ViewBuilder
    private func brandProductsSection() -> some View {
        if !vm.filteredProducts.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Produkty")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(vm.filteredProducts) { product in
                        OverlayProductCardView(
                            product: product,
                            isFavorited: vm.favoriteProductIds.contains(product.id),
                            isCartAdded: cartAddedProductId == product.id,
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
                                        cartAddedProductId = product.id
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        cartAddedProductId = nil
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Helpers
    private func formattedIG(_ handle: String) -> String {
        handle.contains("https://") ? handle : "https://instagram.com/\(handle)"
    }
}
