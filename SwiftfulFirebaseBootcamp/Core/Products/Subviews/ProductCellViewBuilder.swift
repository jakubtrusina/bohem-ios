import SwiftUI

struct ProductCellViewBuilder: View {
    
    let productId: String
    var onAddToCart: (() -> Void)? = nil
    var onShowMoreInfo: (() -> Void)? = nil

    @State private var product: Product? = nil
    
    var body: some View {
        ZStack {
            if let product {
                ProductCellView(
                    product: product,
                    addToCart: onAddToCart,
                    showMoreInfo: onShowMoreInfo
                )
            }
        }
        .task {
            self.product = try? await ProductsManager.shared.getProduct(productId: productId)
        }
    }
}
