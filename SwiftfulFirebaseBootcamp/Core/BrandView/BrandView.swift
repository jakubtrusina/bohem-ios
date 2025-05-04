import SwiftUI
import Kingfisher

struct BrandView: View {
    let brand: Brand?
    let vm = ProductsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                bannerSection()
                brandInfoSection()
                productGridSection()
            }
        }
        .navigationTitle(brand?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.allProducts.isEmpty {
                vm.getProducts()
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func bannerSection() -> some View {
        ZStack(alignment: .bottom) {
            if let bannerUrl = brand?.bannerUrl, let banner = URL(string: bannerUrl) {
                KFImage(banner)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 220)
            }

            brandLogoView()
        }
        .padding(.bottom, 60)
    }

    @ViewBuilder
    private func brandLogoView() -> some View {
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

    @ViewBuilder
    private func brandInfoSection() -> some View {
        VStack(spacing: 10) {
            Text(brand?.name ?? "Brand")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            if let description = brand?.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 20) {
                if let website = brand?.website, let websiteUrl = URL(string: website) {
                    Link(destination: websiteUrl) {
                        Image(systemName: "globe")
                    }
                }

                if let instagram = brand?.instagram, let ig = URL(string: instagram) {
                    Link(destination: ig) {
                        Image(systemName: "camera")
                            .foregroundColor(.pink)
                    }
                }

                if let email = brand?.email {
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                    }
                }
            }
            .font(.title3)
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
        guard let brandName = brand?.name else { return [] }
        return vm.allProducts.filter { $0.brand == brandName }
    }
}
