import SwiftUI
import FirebaseAnalytics

struct OrderSummarySection: View {
    let items: [CartItem]
    let total: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Shrnutí objednávky", systemImage: "doc.text")
                .font(.headline)
                .onAppear {
                    Analytics.logEvent("order_summary_viewed", parameters: [
                        "item_count": items.count,
                        "total": total
                    ])
                }

            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.title ?? "")
                        .font(.subheadline)
                        .bold()
                    Text("Velikost: \(item.size.size) • Množství: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("CZK \(Double(item.product.price ?? 0), specifier: "%.2f")")
                        .font(.caption)
                }
                .padding(.vertical, 4)
                .onAppear {
                    Analytics.logEvent("order_summary_item_viewed", parameters: [
                        "product_id": item.product.id,
                        "title": item.product.title ?? "",
                        "price": item.product.price ?? 0,
                        "size": item.size.size,
                        "quantity": item.quantity
                    ])
                }
            }

            Divider()

            HStack {
                Text("Celkem:")
                    .font(.headline)
                Spacer()
                Text("CZK \(total, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
