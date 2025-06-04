import SwiftUI
import FirebaseAnalytics

struct OrderSummarySection: View {
    let items: [CartItem]
    let itemTotal: Double
    @Binding var selectedShipping: ShippingOption
    @Binding var selectedPayment: PaymentOption
    @Binding var selectedPickupPoint: PickupPoint?

    private var shippingFee: Double {
        Double(selectedShipping.price)
    }

    private var paymentFee: Double {
        Double(selectedPayment.price)
    }

    private var finalTotal: Double {
        itemTotal + shippingFee + paymentFee
    }

    private var paymentDescription: String {
        switch selectedPayment {
        case .cod: return "Dobírkou"
        case .card: return "Platba kartou"
        case .bankTransfer: return "Bankovní převod"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Shrnutí objednávky", systemImage: "doc.text")
                .font(.headline)
                .onAppear {
                    Analytics.logEvent("order_summary_viewed", parameters: [
                        "item_count": items.count,
                        "item_total": itemTotal,
                        "shipping_fee": shippingFee,
                        "payment_fee": paymentFee,
                        "final_total": finalTotal
                    ])
                }

            // 🛍️ Items List
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

            // 💸 Subtotal
            HStack {
                Text("Cena za položky")
                Spacer()
                Text("CZK \(itemTotal, specifier: "%.2f")")
            }

            // 🚚 Shipping Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Způsob dopravy")
                    Spacer()
                    Text(selectedShipping.rawValue)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Cena dopravy")
                    Spacer()
                    Text(shippingFee == 0 ? "✅ ZDARMA" : "CZK \(shippingFee, specifier: "%.2f")")
                }
                Text("🕒 Dodání do 14 dní")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if selectedShipping.requiresPickupPoint, let point = selectedPickupPoint {
                VStack(alignment: .leading, spacing: 2) {
                    Text("📍 Vybraná pobočka")
                        .font(.subheadline.bold())
                    Text("\(point.name)")
                        .font(.caption)
                    Text("\(point.address), \(point.city)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }


            // 💳 Payment Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Způsob platby")
                    Spacer()
                    Text(paymentDescription)
                }
                HStack {
                    Text("Poplatek za platbu")
                    Spacer()
                    Text(paymentFee == 0 ? "✅ ZDARMA" : "CZK \(paymentFee, specifier: "%.2f")")
                }
            }

            Divider()

            // 🧾 Total
            HStack {
                Text("Celkem:")
                    .font(.headline)
                Spacer()
                Text("CZK \(finalTotal, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
