import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics

struct CartView: View {
    @State private var fullName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var zip = ""
    @State private var phone = ""
    @StateObject private var cartManager = CartManager.shared
    @State private var showCheckout = false
    @State private var hasLoggedScreenView = false

    private var subtotal: Double {
        cartManager.cartItems.reduce(0.0) {
            $0 + Double($1.product.price ?? 0) * Double($1.quantity)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack {
                headerSection
                freeShippingBanner
                cartItemsScrollView
                subtotalSection

                NavigationLink(
                    destination: CheckoutView(
                        fullName: $fullName,
                        address: $address,
                        city: $city,
                        zip: $zip,
                        phone: $phone
                    ),
                    isActive: $showCheckout
                ) {
                    Text("Pokračovat k platbě")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(cartManager.cartItems.isEmpty ? Color.gray : Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(cartManager.cartItems.isEmpty)
                .simultaneousGesture(TapGesture().onEnded {
                    AnalyticsManager.shared.logCustomEvent(name: "cart_checkout_pressed", params: [
                        "item_count": cartManager.cartItems.count,
                        "subtotal": subtotal
                    ])
                    showCheckout = true
                })

                Spacer()
            }
            .onAppear {
                cartManager.loadCartItems()
                loadSavedShippingInfo()

                if !hasLoggedScreenView {
                    AnalyticsManager.shared.logEvent(.screenView, params: [
                        "screen_name": "CartView"
                    ])
                    hasLoggedScreenView = true
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Můj Košík (\(cartManager.cartItems.count))")
                .font(.title2.bold())
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var freeShippingBanner: some View {
        HStack {
            Image(systemName: "shippingbox")
            Text("Doprava zdarma na všechny objednávky.")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var cartItemsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach($cartManager.cartItems.indices, id: \.self) { index in
                    let binding = $cartManager.cartItems[index]
                    let item = binding.wrappedValue

                    if let sizes = item.product.sizes {
                        CartItemRowView(
                            item: binding,
                            onUpdateSize: { newSize in
                                Task {
                                    await cartManager.updateSize(item: item, newSize: newSize)
                                    AnalyticsManager.shared.logCustomEvent(name: "cart_size_updated", params: [
                                        "product_id": item.product.id,
                                        "title": item.product.title ?? "",
                                        "new_size": newSize.size
                                    ])
                                }
                            },
                            onRemove: {
                                Task {
                                    await cartManager.remove(docId: item.id)
                                    AnalyticsManager.shared.logCustomEvent(name: "cart_item_removed", params: [
                                        "product_id": item.product.id,
                                        "title": item.product.title ?? "",
                                        "price": item.product.price ?? 0,
                                        "quantity": item.quantity
                                    ])
                                }
                            },
                            stock: item.product.sizes ?? []
                        )
                    }
                }
            }
            .padding()
        }
    }

    private var subtotalSection: some View {
        HStack {
            Text("Celková částka")
                .fontWeight(.bold)
            Spacer()
            Text(String(format: "%.2f CZK", subtotal))
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }

    private func loadSavedShippingInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data()? ["shippingInfo"] as? [String: String] else { return }

            fullName = data["fullName"] ?? ""
            address = data["address"] ?? ""
            city = data["city"] ?? ""
            zip = data["zip"] ?? ""
            phone = data["phone"] ?? ""
        }
    }
}

struct CartItemRowView: View {
    @Binding var item: CartItem
    let onUpdateSize: (ProductSize) -> Void
    let onRemove: () -> Void
    let stock: [ProductSize]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KFImage(URL(string: item.product.thumbnail ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.product.title ?? "Produkt")
                    .font(.headline)

                Text("Cena: \(Double(item.product.price ?? 0), specifier: "%.2f") CZK")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Velikost", selection: $item.size.size) {
                    ForEach(stock, id: \.size) { size in
                        Text(size.size).tag(size.size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: item.size.size) { newValue in
                    if let new = stock.first(where: { $0.size == newValue }) {
                        onUpdateSize(new)
                    }
                }

                HStack(spacing: 16) {
                    Text("Množství: \(item.quantity)")
                        .font(.subheadline)

                    Stepper("", value: $item.quantity, in: 1...10)
                        .onChange(of: item.quantity) { newQty in
                            Task {
                                await CartManager.shared.updateQuantity(docId: item.id, quantity: newQty)
                                AnalyticsManager.shared.logCustomEvent(name: "cart_quantity_updated", params: [
                                    "product_id": item.product.id,
                                    "title": item.product.title ?? "",
                                    "new_quantity": newQty
                                ])
                            }
                        }
                }

                Button(action: onRemove) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Odebrat")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.footnote)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
