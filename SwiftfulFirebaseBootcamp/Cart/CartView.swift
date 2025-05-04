import SwiftUI
import PassKit
import Stripe
import FirebaseFunctions
import FirebaseAuth
import SafariServices
import Kingfisher

struct CartView: View {
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var applePayCoordinator: ApplePayCoordinatorWrapper? = nil
    @State private var checkoutURL: URL? = nil
    @State private var showingSafari = false
    @State private var isSignedIn = false

    private var subtotal: Double {
        cartManager.cartItems.reduce(0.0) {
            $0 + Double($1.product.price ?? 0) * Double($1.quantity)
        }
    }

    var body: some View {
        VStack {
            headerSection
            freeShippingBanner
            cartItemsScrollView
            Divider()
            subtotalSection
            Spacer()
            paymentButtons
        }
        .onAppear {
            cartManager.loadCartItems()
            Task {
                do {
                    if Auth.auth().currentUser == nil {
                        try await authViewModel.signInAnonymous()
                        print("✅ New anonymous user signed in")
                    } else {
                        print("✅ Already signed in as:", Auth.auth().currentUser?.uid ?? "nil")
                    }
                    isSignedIn = true
                } catch {
                    print("❌ Anonymous sign-in failed:", error.localizedDescription)
                }
            }
            AnalyticsManager.shared.logEvent(.screenView, params: ["screen_name": String(describing: Self.self)])
        }
        .sheet(isPresented: $showingSafari) {
            if let url = checkoutURL {
                SafariView(url: url)
            }
        }
        .navigationTitle("menu_cart")
    }

    private var headerSection: some View {
        HStack {
            Text("My Bag (\(cartManager.cartItems.count))")
                .font(.title2.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var freeShippingBanner: some View {
        HStack {
            Image(systemName: "shippingbox")
            Text("Enjoy free standard shipping.")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var cartItemsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(cartManager.cartItems.indices, id: \ .self) { index in
                    CartItemRowView(item: $cartManager.cartItems[index])
                        .id(cartManager.cartItems[index].id + "-\(cartManager.cartItems[index].quantity)")
                }
            }
            .padding()
        }
    }

    private var subtotalSection: some View {
        HStack {
            Text("Estimated Total")
                .fontWeight(.bold)
            Spacer()
            Text(String(format: "%.2f CZK", subtotal))
                .fontWeight(.bold)
        }
        .padding(.horizontal)
    }

    private var paymentButtons: some View {
        VStack(spacing: 12) {
            Button {
                startApplePay()
            } label: {
                HStack {
                    Image(systemName: "applelogo")
                    Text("Buy with Apple Pay")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(10)
            }

            Button {
                startStripeCheckout()
            } label: {
                Text("Pay with Card (Stripe Checkout)")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    func startStripeCheckout() {
        guard isSignedIn, let user = Auth.auth().currentUser else {
            print("❌ Cannot proceed — user not signed in")
            return
        }

        let items = cartManager.cartItems.map { item in
            [
                "productId": item.product.id,
                "quantity": item.quantity,
                "size": item.size.size,
                "price": item.product.price ?? 1000
            ]
        }


        Functions.functions()
            .httpsCallable("createCheckoutSessionV1_fixed")
            .call(["items": items]) { result, error in
                if let error = error {
                    print("❌ Stripe Checkout error:", error.localizedDescription)
                    return
                }

                if let data = result?.data as? [String: Any],
                   let urlString = data["url"] as? String,
                   let url = URL(string: urlString) {
                    print("🌐 Stripe Checkout URL:", url)
                    UIApplication.shared.open(url)
                } else {
                    print("❌ Invalid response from Stripe Checkout")
                }
            }
    }

    func startApplePay() {
        guard StripeAPI.deviceSupportsApplePay() else {
            print("❌ Apple Pay not available")
            return
        }

        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.bohem.store",
            country: "CZ",
            currency: "CZK"
        )
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Bohem Order", amount: NSDecimalNumber(decimal: Decimal(subtotal)))
        ]

        let coordinator = ApplePayCoordinatorWrapper(cartTotal: subtotal)
        applePayCoordinator = coordinator

        if let context = STPApplePayContext(paymentRequest: request, delegate: coordinator) {
            context.presentApplePay()
        }
    }
}

struct CartItemRowView: View {
    @Binding var item: CartItem

    var body: some View {
        HStack(spacing: 16) {
            if let urlString = item.product.thumbnail,
               let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .cancelOnDisappear(true)
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.product.title ?? "")
                    .font(.headline)
                    .lineLimit(2)

                Text("\(item.product.price ?? 0) CZK")
                    .font(.subheadline)

                Picker("Size", selection: $item.size) {
                    ForEach(item.product.sizes ?? [], id: \ .self) { size in
                        Text("\(size.size) (\(size.stock))").tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: item.size) { newSize in
                    Task {
                        await CartManager.shared.updateSize(item: item, newSize: newSize)
                    }
                }

                Stepper(value: $item.quantity, in: 1...10) {
                    Text("Qty: \(item.quantity)")
                }
                .onChange(of: item.quantity) { newQty in
                    Task {
                        await CartManager.shared.updateQuantity(docId: "\(item.product.id)-\(item.size.size)", quantity: newQty)
                    }
                }
            }

            Spacer()

            Button {
                Task {
                    await CartManager.shared.remove(productId: item.product.id, size: item.size.size)
                }
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

class ApplePayCoordinatorWrapper: NSObject, STPApplePayContextDelegate {
    let cartTotal: Double

    init(cartTotal: Double) {
        self.cartTotal = cartTotal
    }

    func applePayContext(_ context: STPApplePayContext,
                         didCreatePaymentMethod paymentMethod: STPPaymentMethod,
                         paymentInformation: PKPayment,
                         completion: @escaping STPIntentClientSecretCompletionBlock) {
        Functions.functions()
            .httpsCallable("createPaymentIntent")
            .call(["amount": Int(cartTotal * 100), "currency": "czk"]) { result, error in
                if let error = error {
                    completion(nil, error)
                } else if let data = result?.data as? [String: Any],
                          let clientSecret = data["clientSecret"] as? String {
                    completion(clientSecret, nil)
                } else {
                    completion(nil, NSError(domain: "Stripe", code: -1, userInfo: nil))
                }
            }
    }

    func applePayContext(_ context: STPApplePayContext,
                         didCompleteWith status: STPPaymentStatus,
                         error: Error?) {
        switch status {
        case .success:
            print("✅ Apple Pay Success")
        case .error:
            print("❌ Apple Pay Error:", error?.localizedDescription ?? "")
        case .userCancellation:
            print("⚠️ Apple Pay Cancelled")
        @unknown default:
            break
        }
    }
}
