import SwiftUI
import Kingfisher

struct SliderProductCardView: View {
    let product: Product
    let isFavorited: Bool
    let isCartAdded: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCart: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                // 🖼 Product Image
                KFImage(URL(string: product.thumbnail ?? ""))
                    .resizable()
                    .cancelOnDisappear(true)
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: 160, height: 220)
                    .clipped()

                // 📝 Info Overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title ?? "")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(product.brand ?? "")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.85))

                    if let price = product.price {
                        Text("\(price) CZK")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            }

            // ❤️ Favorite Button
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(6)

            // 🛍 Cart Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onAddToCart) {
                        Image(systemName: isCartAdded ? "checkmark.circle.fill" : "bag.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(6)
                }
            }
        }
        .frame(width: 160, height: 220)
        .cornerRadius(14)
        .clipped()
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
}
