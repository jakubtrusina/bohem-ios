//import SwiftUI
//
//struct ProductDetailView: View {
//    let product: Product
//    
//    @State private var isProcessingCart = false
//    @State private var isProcessingFavorite = false
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//
//                // 🖼 Image Carousel
//                if let images = product.images {
//                    TabView {
//                        ForEach(images.prefix(5), id: \.self) { url in
//                            AsyncImage(url: URL(string: url)) { image in
//                                image
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(maxWidth: .infinity)
//                                    .clipped()
//                            } placeholder: {
//                                Color.gray.opacity(0.2)
//                            }
//                        }
//                    }
//                    .frame(height: 320)
//                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                    .clipShape(RoundedRectangle(cornerRadius: 16))
//                }
//
//                // 📦 Product Info
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(product.title ?? "Untitled")
//                        .font(.title)
//                        .fontWeight(.semibold)
//
//                    Text("CZK \(product.price)")
//                        .font(.title2)
//                        .fontWeight(.medium)
//                        .foregroundColor(.secondary)
//
//                    Text("Rating: \(product.rating)")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//
//                    Text("Category: \(product.category ?? "Unknown")")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//
//                    Text("Brand: \(product.brand ?? "Unknown")")
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//                }
//
//                // 🔘 Action Buttons
//                HStack(spacing: 16) {
//                    Button(action: {
//                        Task {
//                            isProcessingCart = true
//                            await userActionsManager.addToCart(product: product)
//                            isProcessingCart = false
//                        }
//                    }) {
//                        HStack {
//                            Image(systemName: userActionsManager.addedToCartProductIds.contains(product.id) ? "checkmark.circle.fill" : "cart.badge.plus")
//                            Text(userActionsManager.addedToCartProductIds.contains(product.id) ? "Added!" : "Add to Cart")
//                        }
//                        .font(.subheadline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.black)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                        .scaleEffect(userActionsManager.addedToCartProductIds.contains(product.id) ? 1.05 : 1.0)
//                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: userActionsManager.addedToCartProductIds.contains(product.id))
//                    }
//
//                    Button(action: {
//                        let generator = UIImpactFeedbackGenerator(style: .medium)
//                        generator.impactOccurred()
//                        
//                        Task {
//                            isProcessingFavorite = true
//                            await userActionsManager.toggleFavorite(product: product)
//                            isProcessingFavorite = false
//                        }
//                    }) {
//                        HStack {
//                            Image(systemName: userActionsManager.favoriteProductIds.contains(product.id) ? "heart.fill" : "heart")
//                            Text("Favorite")
//                        }
//                        .font(.subheadline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.red.opacity(0.9))
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                        .scaleEffect(userActionsManager.favoriteProductIds.contains(product.id) ? 1.1 : 1.0)
//                        .animation(.easeInOut(duration: 0.3), value: userActionsManager.favoriteProductIds.contains(product.id))
//                    }
//                }
//            }
//            .padding()
//        }
//        .navigationTitle("Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .background(Color(.systemGroupedBackground))
//        .onAppear {
//            Task {
//                await userActionsManager.loadFavorites()
//            }
//        }
//    }
//}
