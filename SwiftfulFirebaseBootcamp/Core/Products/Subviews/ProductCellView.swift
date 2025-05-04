//
//  ProductCellView.swift
//  SwiftfulFirebaseBootcamp
//


import SwiftUI
import Kingfisher


struct ProductCellView: View {
    let product: Product
    var addToCart: (() -> Void)?
    var addToFavorites: (() -> Void)?
    var showMoreInfo: (() -> Void)?

    @State private var cartAdded = false
    @State private var favoriteAdded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                KFImage(URL(string: product.thumbnail ?? ""))
                    .resizable()
                    .cancelOnDisappear(true)
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: 75, height: 75)
                    .cornerRadius(10)
                    .clipped()
                .frame(width: 75, height: 75)

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title ?? "n/a")
                        .font(.headline)
                    Text("$\(product.price ?? 0)")
                    Text("Category: \(product.category ?? "n/a")")
                    Text("Brand: \(product.brand ?? "n/a")")
                }
                .font(.callout)
                .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    showMoreInfo?()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Button(action: {
                    addToCart?()
                    withAnimation(.spring()) {
                        cartAdded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        cartAdded = false
                    }
                }) {
                    HStack {
                        Image(systemName: cartAdded ? "checkmark.circle.fill" : "cart.badge.plus")
                        Text(cartAdded ? "Added!" : "Add to Cart")
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(cartAdded ? 1.1 : 1.0)
                }

                Button(action: {
                    addToFavorites?()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        favoriteAdded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        favoriteAdded = false
                    }
                }) {
                    HStack {
                        Image(systemName: favoriteAdded ? "heart.fill" : "heart")
                        Text(favoriteAdded ? "Favorited!" : "Favorite")
                    }
                    .font(.subheadline)
                    .padding(8)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(favoriteAdded ? 1.1 : 1.0)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Prevents tap conflicts
        .onTapGesture {} // Blocks accidental navigation
    }
}



struct ProductCellView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCellView(
            product: Product(
                id: "1",
                title: "Test Product",
                description: ["en": "Preview product description", "cs": "Ukázkový popis produktu"],
                price: 435,
                discountPercentage: 10.0,
                rating: 4.5,
                stock: 25,
                brand: "PreviewBrand",
                category: "PreviewCategory",
                subcategory: "PreviewSubcategory",
                thumbnail: "https://example.com/thumbnail.jpg",
                images: [],
                sizes: [],
                alternativeProducts: [],
                similarProducts: [],
                category_normalized: "previewcategory",
                subcategory_normalized: "previewsubcategory",
                popularity: 100,
                isNewArrival: true,
                createdAt: "2025-05-01T00:00:00Z",
                material: "Cotton",
                fit: "Regular",
                colors: [],
                styleTags: [],
                season: [],
                gender: "female",
                care: "Wash cold",
                designerNote: "This is a designer note.",
                model: ProductModel(height_cm: 170, wearing_size: "M"),
                relatedProductIds: []
            )
        )
    }
}
