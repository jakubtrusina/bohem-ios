import SwiftUI

struct ProductSliderScrollView: View {
    let products: [Product]
    let favoriteProductIds: Set<String>
    let cartAddedProductIds: Set<String>
    let onTap: (Product) -> Void
    let onToggleFavorite: (Product) -> Void
    let onAddToCart: (Product) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(products) { product in
                    SliderProductCardView(
                        product: product,
                        isFavorited: favoriteProductIds.contains(product.id),
                        isCartAdded: cartAddedProductIds.contains(product.id),
                        onTap: { onTap(product) },
                        onToggleFavorite: { onToggleFavorite(product) },
                        onAddToCart: { onAddToCart(product) }
                    )
                    .frame(width: 160)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 220) // slightly taller for better visuals
    }
}
