import SwiftUI
import Kingfisher


struct OverlayProductCardView: View {
    let product: Product
    let isFavorited: Bool
    let isCartAdded: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCart: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                // Product image or fallback
                if let urlString = product.thumbnail,
                   let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.25)
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            AnalyticsManager.shared.logAddToFavorites(product: product)
                            onTap()
                        }
                } else {
                    Color.gray.opacity(0.2)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(Text("No image").foregroundColor(.white))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title ?? "Unnamed")
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(product.brand ?? "")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))

                    if let price = product.price {
                        Text("\(price) CZK")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            }

            // ❤️ Favorite button
            Button {
                AnalyticsManager.shared.logAddToFavorites(product: product)
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding([.top, .trailing], 10)
            }

            // 🛍 Add to Cart button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        AnalyticsManager.shared.logAddToCart(product: product, quantity: 1)
                        onAddToCart()
                    } label: {
                        Image(systemName: isCartAdded ? "checkmark.circle.fill" : "bag.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding([.trailing, .bottom], 12)
                    }
                }
            }
        }
        .cornerRadius(14)
        .clipped()
    }
}
