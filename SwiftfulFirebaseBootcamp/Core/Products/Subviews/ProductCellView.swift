//
//  ProductCellView.swift
//  SwiftfulFirebaseBootcamp
//


import SwiftUI

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
                AsyncImage(url: URL(string: product.thumbnail ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 75, height: 75)

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title ?? "n/a")
                        .font(.headline)
                    Text("$\(product.price ?? 0)")
                    Text("Rating: \(product.rating ?? 0)")
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
        ProductCellView(product: Product(id: 1, title: "Test", description: "test", price: 435, discountPercentage: 1345245, rating: 65231, stock: 1324, brand: "asdfasdf", category: "asdfafsd", thumbnail: "asdfafds", images: []))
    }
}
