import SwiftUI
import PassKit
import Stripe
import FirebaseFunctions
import FirebaseAuth
import SafariServices

struct CartView: View {
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var applePayCoordinator: ApplePayCoordinatorWrapper? = nil
    @State private var checkoutURL: URL? = nil
    @State private var showingSafari = false
    @State private var isSignedIn = false

    var body: some View {
        let subtotal = cartManager.cartItems.reduce(0.0) {
            $0 + Double($1.product.price ?? 0) * Double($1.quantity)
        }

        return VStack {
            HStack {
                Text("My Bag (\(cartManager.cartItems.count))")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            // Free shipping
            HStack {
                Image(systemName: "shippingbox")
                Text("Enjoy free standard shipping.")
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))

            // Cart Items
            ScrollView {
                ForEach(cartManager.cartItems, id: \.id) { item in
                    HStack(spacing: 16) {
                        if let urlString = item.product.thumbnail,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 120)
                                    .clipped()
                            } placeholder: {
                                ProgressView().frame(width: 100, height: 120)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.product.title ?? "")
                                .font(.headline)
                                .lineLimit(2)

                            Text("\(item.product.price ?? 0) CZK")
                                .font(.subheadline)

                            Text("Size: \(item.size)")

                            Stepper("Qty: \(item.quantity)", value: Binding(
                                get: { item.quantity },
                                set: { newQty in
                                    Task {
                                        let docId = "\(item.product.id)-\(item.size)"
                                        await cartManager.updateQuantity(docId: docId, quantity: newQty)
                                    }
                                }
                            ), in: 1...10)
                        }

                        Spacer()

                        Button {
                            Task {
                                await cartManager.remove(productId: item.product.id, size: item.size)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Subtotal
            HStack {
                Text("Estimated Total")
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: "%.2f CZK", subtotal))
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            Spacer()

            // Payment Buttons
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

            let screenName = String(describing: Self.self)
            AnalyticsManager.shared.logEvent(.screenView, params: [
                "screen_name": screenName
            ])
        }


        .sheet(isPresented: $showingSafari) {
            if let url = checkoutURL {
                SafariView(url: url)
            }
        }
        .navigationTitle("Cart")
    }

    // MARK: - Stripe Checkout

    func startStripeCheckout() {
        guard isSignedIn, let user = Auth.auth().currentUser else {
            print("❌ Cannot proceed — user not signed in")
            return
        }

        print("🧪 Proceeding to Stripe Checkout as:", user.uid)

        let items = cartManager.cartItems.map { item in
            [
                "productId": item.product.id,
                "quantity": item.quantity,
                "size": item.size,
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
                    UIApplication.shared.open(url) // ✅ Open in full Safari
                } else {
                    print("❌ Invalid response from Stripe Checkout")
                }
            }
    }


    // MARK: - Apple Pay

    func startApplePay() {
        guard StripeAPI.deviceSupportsApplePay() else {
            print("❌ Apple Pay not available")
            return
        }

        let total = cartManager.cartItems.reduce(0.0) {
            $0 + Double($1.product.price ?? 0) * Double($1.quantity)
        }

        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "merchant.com.bohem.store",
            country: "CZ",
            currency: "CZK"
        )
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Bohem Order", amount: NSDecimalNumber(value: total))
        ]

        let coordinator = ApplePayCoordinatorWrapper(cartTotal: total)
        applePayCoordinator = coordinator

        if let context = STPApplePayContext(paymentRequest: request, delegate: coordinator) {
            context.presentApplePay()
        }
    }
}

// MARK: - Apple Pay Delegate

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

// MARK: - Safari Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
