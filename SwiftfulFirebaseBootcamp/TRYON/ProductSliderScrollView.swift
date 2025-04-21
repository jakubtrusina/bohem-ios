import SwiftUI

struct ProductSliderScrollView: View {
    let products: [Product]
    let favoriteProductIds: Set<Int>
    let cartAddedProductId: Int?
    let onTap: (Product) -> Void
    let onToggleFavorite: (Product) -> Void
    let onAddToCart: (Product) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 16) {
                ForEach(products) { product in
                    SliderProductCardView(
                        product: product,
                        isFavorited: favoriteProductIds.contains(product.id),
                        isCartAdded: cartAddedProductId == product.id,
                        onTap: { onTap(product) },
                        onToggleFavorite: { onToggleFavorite(product) },
                        onAddToCart: { onAddToCart(product) }
                    )
                    .frame(width: 160)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 250)
    }
}
