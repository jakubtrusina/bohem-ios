import SwiftUI

struct SingleProductView: View {
    let product: Product

    @State private var isFavorited = false
    @State private var cartAdded = false
    @State private var selectedImageUrl: String?
    @State private var selectedBrand: String? = nil

    @State private var selectedSize: String = "M"
    @State private var quantity: Int = 1

    let availableSizes = ["XS", "S", "M", "L", "XL"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: selectedImageUrl ?? product.thumbnail ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .aspectRatio(1, contentMode: .fit)
                    }

                    Button {
                        Task {
                            if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
                                if isFavorited {
                                    try? await UserManager.shared.removeUserFavoriteProductByProductId(userId: user.uid, productId: product.id)
                                } else {
                                    try? await UserManager.shared.addUserFavoriteProduct(userId: user.uid, productId: product.id)
                                }
                                withAnimation {
                                    isFavorited.toggle()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(12)
                    }
                }

                if let images = product.images, !images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(images, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
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
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                            .frame(width: 80, height: 100)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.title ?? "Unnamed")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let brand = product.brand {
                        Button(action: {
                            selectedBrand = brand
                        }) {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }

                    if let price = product.price {
                        Text("$\(price)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    if let discount = product.discountPercentage {
                        Text("Discount: \(String(format: "%.0f", discount))%")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }

                    if let rating = product.rating {
                        Text("Rating: ⭐️ \(String(format: "%.1f", rating))/5")
                            .font(.subheadline)
                    }

                    if let stock = product.stock {
                        Text("Stock: \(stock) left")
                            .font(.subheadline)
                            .foregroundColor(stock > 5 ? .primary : .red)
                    }

                    if let category = product.category {
                        Text("Category: \(category.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider().padding(.vertical, 8)

                    if let desc = product.description {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .padding()

                // Size & Quantity Selection
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Select Size")
                            .font(.subheadline)
                        Picker("Size", selection: $selectedSize) {
                            ForEach(availableSizes, id: \.self) { size in
                                Text(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...10)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 80)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()

                Button(action: {
                    Task {
                        await CartManager.shared.addToCart(product: product, size: selectedSize, quantity: quantity)
                        withAnimation {
                            cartAdded = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            cartAdded = false
                        }
                    }
                }) {
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
        .sheet(item: $selectedBrand) { brandName in
            BrandView(brandName: brandName)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            selectedImageUrl = product.thumbnail
            if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
                let favs = try? await UserManager.shared.getAllUserFavoriteProducts(userId: user.uid)
                isFavorited = favs?.contains(where: { $0.productId == product.id }) ?? false
            }
        }
        .onAppear {
            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": "SingleProductView",
                "item_id": product.id,
                "item_name": product.title ?? ""
            ])
        }
    
    }
}

extension String: Identifiable {
    public var id: String { self }
}
