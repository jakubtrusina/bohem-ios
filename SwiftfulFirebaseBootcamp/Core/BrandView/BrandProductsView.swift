import SwiftUI
import Kingfisher

struct BrandProductsView: View {
    let brand: Brand
    @StateObject private var viewModel = ProductsViewModel()
    @State private var selectedProduct: Product? = nil
    @State private var isShowingDetail = false
    @State private var cartAddedProductId: String? = nil
    @ObservedObject private var vm = ProductsViewModel.shared
    @State private var didLoad = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                brandHeader
                productGridSection()
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            viewModel.selectedBrands = [brand.name]
            viewModel.getProducts()
            viewModel.loadFavoriteProductIds()
        }
        .navigationDestination(isPresented: $isShowingDetail) {
            if let product = selectedProduct {
                SingleProductView(productId: product.id)
            }
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 0) {
            if let bannerUrl = brand.bannerUrl, let banner = URL(string: bannerUrl) {
                KFImage(banner)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 220)
            }

            if let logoUrl = brand.logoUrl, let logo = URL(string: logoUrl) {
                KFImage(logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 4)
                    .offset(y: -50)
                    .padding(.bottom, -40)
            }
        }
    }

    @ViewBuilder
    private func productGridSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Produkty")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(getFilteredProducts()) { product in
                    NavigationLink(destination: SingleProductView(productId: product.id)) {
                        VStack(spacing: 8) {
                            if let thumb = product.thumbnail, let url = URL(string: thumb) {
                                KFImage(url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .clipped()
                                    .cornerRadius(8)
                            }

                            Text(product.title ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)

                            if let price = product.price {
                                Text("\(price) CZK")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func getFilteredProducts() -> [Product] {
        return viewModel.filteredProducts.filter { $0.brand == brand.name }
    }
}
