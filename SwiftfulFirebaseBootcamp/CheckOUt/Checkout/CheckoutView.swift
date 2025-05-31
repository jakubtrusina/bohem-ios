import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PassKit
import Stripe
import FirebaseFunctions
import StripePaymentSheet

struct CheckoutView: View {
    @State private var showSavedInfoMessage = false
    @Binding var fullName: String
    @Binding var address: String
    @Binding var city: String
    @Binding var zip: String
    @Binding var phone: String
    @State private var isSubmitting = false
    @State private var orderSubmitted = false
    @State private var applePayDelegate: ApplePayDelegate? = nil
    @State private var isLaunchingApplePay = false
    @State private var paymentSheet: PaymentSheet?
    @State private var paymentResult: PaymentSheetResult?

    @ObservedObject var cartManager = CartManager.shared

    var body: some View {
        ZStack {
            checkoutContent

            if !orderSubmitted {
                stickyBottomButtons
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsManager.shared.logCustomEvent(name: "checkout_view_opened")
        }
        .overlay(submissionOverlay)
        .overlay(savedInfoMessageOverlay, alignment: .top)
    }

    private var checkoutContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GroupBox(label: Text("Doručovací údaje").bold()) {
                    ShippingInfoSection(fullName: $fullName, address: $address, city: $city, zip: $zip, phone: $phone)
                }

                Divider()

                OrderSummarySection(items: cartManager.cartItems, total: cartTotal)

                Divider()

                if orderSubmitted {
                    VStack(spacing: 16) {
                        Text("✅ Objednávka úspěšně odeslána!")
                            .foregroundColor(.green)
                            .font(.title3.bold())
                        Button("Zpět do obchodu") {
                            // Navigation logic if needed
                        }
                    }
                }

                Spacer(minLength: 80)
            }
            .padding([.horizontal, .bottom])
        }
    }

    private var stickyBottomButtons: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ApplePayButton {
                    AnalyticsManager.shared.logCustomEvent(name: "payment_method_selected", params: ["method": "apple_pay"])
                    isLaunchingApplePay = true
                    startApplePay()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLaunchingApplePay = false
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.black)


                Button(action: {
                    if isFormValid {
                        AnalyticsManager.shared.logCustomEvent(name: "payment_method_selected", params: ["method": "card"])
                        preparePaymentSheet()
                    }
                }) {
                    Text("Zaplatit kartou")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .foregroundColor(.white)
                }
                .disabled(!isFormValid || isSubmitting)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .transition(.move(edge: .bottom))
    }

    private var submissionOverlay: some View {
        Group {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Zpracovávám objednávku…")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .shadow(radius: 10)
                }
            }
        }
    }

    private var savedInfoMessageOverlay: some View {
        Group {
            if showSavedInfoMessage {
                Text("✅ Doručovací údaje byly uloženy")
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.top, 60)
                    .transition(.opacity)
            }
        }
    }

    private var cartTotal: Double {
        cartManager.cartItems.reduce(0.0) {
            $0 + (Double($1.product.price ?? 0) * Double($1.quantity))
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !address.isEmpty && !city.isEmpty && !zip.isEmpty && !phone.isEmpty
    }

    private func saveOrderToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let order: [String: Any] = [
            "userId": uid,
            "timestamp": Timestamp(),
            "fullName": fullName,
            "address": address,
            "city": city,
            "zip": zip,
            "phone": phone,
            "items": cartManager.cartItems.map {
                [
                    "title": $0.product.title ?? "",
                    "productId": $0.product.id,
                    "size": ["size": $0.size.size, "stock": $0.size.stock],
                    "quantity": $0.quantity,
                    "price": $0.product.price ?? 0
                ]
            },
            "total": cartTotal
        ]

        do {
            try await Firestore.firestore().collection("orders").addDocument(data: order)
            orderSubmitted = true
        } catch {
            print("❌ Failed to save order:", error)
        }
    }

    private func submitOrder() {
        isSubmitting = true
        Task {
            await saveOrderToFirestore()
            await saveShippingInfoToUser()
            isSubmitting = false
        }
    }

    private func saveShippingInfoToUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let info: [String: Any] = [
            "shippingInfo": [
                "fullName": fullName,
                "address": address,
                "city": city,
                "zip": zip,
                "phone": phone
            ]
        ]

        do {
            try await Firestore.firestore().collection("users").document(uid).setData(info, merge: true)
            DispatchQueue.main.async {
                showSavedInfoMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSavedInfoMessage = false
                }
            }
        } catch {
            print("❌ Failed to save shipping info:", error)
        }
    }

    private func startApplePay() {
        guard PKPaymentAuthorizationController.canMakePayments(),
              PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]) else {
            print("❌ Apple Pay not available or no card configured")
            return
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.bohem.store"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "CZ"
        request.currencyCode = "CZK"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Bohem Order", amount: NSDecimalNumber(value: cartTotal))
        ]

        let newDelegate = ApplePayDelegate {
            Task {
                await saveOrderToFirestore()
            }
        }

        self.applePayDelegate = newDelegate

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = newDelegate
        controller.present { presented in
            if !presented {
                print("❌ Failed to present Apple Pay sheet")
            }
        }
    }

    private func preparePaymentSheet() {
        let amountInCents = Int(cartTotal * 100)

        let trimmedShipping: [String: Any] = [
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "address": [
                "line1": address.trimmingCharacters(in: .whitespacesAndNewlines),
                "city": city.trimmingCharacters(in: .whitespacesAndNewlines),
                "postal_code": zip.trimmingCharacters(in: .whitespacesAndNewlines),
                "country": "CZ"
            ]
        ]

        Functions.functions().httpsCallable("createPaymentIntent")
            .call([
                "amount": amountInCents,
                "shipping": trimmedShipping
            ]) { result, error in
                if let error = error {
                    print("❌ Stripe error: \(error.localizedDescription)")
                    return
                }

                guard let data = result?.data as? [String: Any],
                      let clientSecret = data["clientSecret"] as? String else {
                    print("❌ Missing clientSecret")
                    return
                }

                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Bohem"
                config.applePay = .init(merchantId: "merchant.com.bohem.store", merchantCountryCode: "CZ")
                config.style = .automatic

                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
                presentPaymentSheet()
            }
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = self.paymentSheet else { return }
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first else {
            print("❌ No window found for PaymentSheet")
            return
        }

        paymentSheet.present(from: window.rootViewController!) { result in
            self.paymentResult = result
            switch result {
            case .completed:
                print("✅ Payment complete")
                AnalyticsManager.shared.logCustomEvent(name: "payment_result", params: ["status": "completed"])
                Task {
                    await saveOrderToFirestore()
                    await saveShippingInfoToUser()
                    isSubmitting = false
                }
            case .canceled:
                print("⚠️ Payment canceled")
                AnalyticsManager.shared.logCustomEvent(name: "payment_result", params: ["status": "canceled"])
            case .failed(let error):
                print("❌ Payment failed: \(error.localizedDescription)")
                AnalyticsManager.shared.logCustomEvent(name: "payment_result", params: [
                    "status": "failed",
                    "error": error.localizedDescription
                ])
            }
        }
    }

    private var applePayView: some View {
        ApplePayButton {
            AnalyticsManager.shared.logCustomEvent(name: "payment_method_selected", params: ["method": "apple_pay"])
            isLaunchingApplePay = true
            startApplePay()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLaunchingApplePay = false
            }
        }
        .frame(height: 50)
    }
}
