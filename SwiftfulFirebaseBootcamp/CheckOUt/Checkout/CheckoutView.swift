import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PassKit
import Stripe
import FirebaseFunctions
import StripePaymentSheet
import Foundation


enum DeliveryMethod: String, CaseIterable {
    case home = "home"
    case pickup = "pickup"
    case cod = "cod"

    var title: String {
        switch self {
        case .home: return "Doručení domů"
        case .pickup: return "Osobní odběr"
        case .cod: return "Na dobírku"
        }
    }
}

enum ShippingOption: String, CaseIterable, Identifiable {
    case ceskaPosta = "Česká pošta do ruky"
    case zasPickup = "Zásilkovna (osobní odběr)"
    case zasAddress = "Zásilkovna doručení na adresu"
    case gls = "GLS"

    var id: String { self.rawValue }

    var price: Int {
        switch self {
        case .ceskaPosta, .zasPickup, .gls: return 0
        case .zasAddress: return 99
        }
    }

    var requiresPickupPoint: Bool {
        self == .zasPickup
    }
}

enum PaymentOption: String, CaseIterable, Identifiable {
    case cod = "Dobírkou"
    case card = "On-line platba kartou"
    case bankTransfer = "On-line bankovní převod"

    var id: String { self.rawValue }

    var price: Int {
        switch self {
        case .cod: return 39
        case .card, .bankTransfer: return 0
        }
    }
}


struct DeliveryOption {
    let method: DeliveryMethod
    let label: String
    let price: Double

    var isFree: Bool { price == 0 }

    var formattedPrice: String {
        isFree ? "ZDARMA" : "\(Int(price)) Kč"
    }

    static let all: [DeliveryOption] = [
        DeliveryOption(method: .home, label: "GLS", price: 0),
        DeliveryOption(method: .pickup, label: "Zásilkovna doručení na adresu", price: 99),
        DeliveryOption(method: .cod, label: "Zásilkovna na dobírku", price: 99)
    ]
}

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
    @State private var selectedDeliveryMethod: DeliveryMethod = .home
    @State private var showZasilkovnaMap = false
    @State private var selectedPickupPoint: PickupPoint? = nil
    @State private var selectedShipping: ShippingOption = .ceskaPosta
    @State private var selectedPayment: PaymentOption = .card
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var cartManager = CartManager.shared

    var body: some View {
        ZStack {
            checkoutContent

        }
        .sheet(isPresented: $showZasilkovnaMap) {
            WidgetWebView { point in
                self.selectedPickupPoint = point
                self.showZasilkovnaMap = false
            }
        }



        .navigationTitle("Checkout")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zpět")
                    }
                    .foregroundColor(.black)
                }
            }
        }

        .onAppear {
            AnalyticsManager.shared.logCustomEvent(name: "checkout_view_opened")
        }
        .overlay(submissionOverlay)
        .overlay(savedInfoMessageOverlay, alignment: .top)
    }

    private func topViewController() -> UIViewController? {
        guard var top = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
                return nil
        }

        while let presented = top.presentedViewController {
            top = presented
        }

        return top
    }

    
    private let functions = Functions.functions()

    private var checkoutContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. Shipping Info
                GroupBox(label: Text("Doručovací údaje").bold()) {
                    ShippingInfoSection(
                        fullName: $fullName,
                        address: $address,
                        city: $city,
                        zip: $zip,
                        phone: $phone
                    )
                }

                // 2. Delivery Method Picker (moved up)
                GroupBox(label: Text("📦 Doprava a Platba").bold()) {
                    VStack(alignment: .leading, spacing: 24) {

                        // 🚚 Shipping Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doprava")
                                .font(.headline)

                            ForEach(ShippingOption.allCases) { option in
                                Button(action: { selectedShipping = option }) {
                                    HStack {
                                        Image(systemName: selectedShipping == option ? "largecircle.fill.circle" : "circle")
                                        Text("\(option.rawValue) \(option.price == 0 ? "ZDARMA" : "\(option.price) Kč")")
                                    }
                                }
                                .foregroundColor(.primary)

                                if option.requiresPickupPoint && selectedShipping == option {
                                    Button(action: {
                                        showZasilkovnaMap = true
                                    }) {
                                        Text(selectedPickupPoint != nil ? "✅ Pobočka vybrána" : "Vybrat pobočku Zásilkovny")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }

                                    if let point = selectedPickupPoint {
                                        Text("📍 \(point.name), \(point.address), \(point.city)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }

                        Divider()

                        // 💳 Payment Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Platba")
                                .font(.headline)

                            ForEach(PaymentOption.allCases) { option in
                                Button(action: { selectedPayment = option }) {
                                    HStack {
                                        Image(systemName: selectedPayment == option ? "largecircle.fill.circle" : "circle")
                                        Text("\(option.rawValue) \(option.price == 0 ? "ZDARMA" : "\(option.price) Kč")")
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }


                // 3. Order Summary
                GroupBox {
                    OrderSummarySection(
                        items: cartManager.cartItems,
                        itemTotal: itemTotal,
                        selectedShipping: $selectedShipping,
                        selectedPayment: $selectedPayment,
                        selectedPickupPoint: $selectedPickupPoint
                    )                }

                PaymentSection(
                    orderSubmitted: orderSubmitted,
                    isSubmitting: isSubmitting,
                    isFormValid: isFormValid,
                    selectedPayment: selectedPayment, // ← updated
                    onSubmit: submitOrder,
                    onCardPay: preparePaymentSheet,
                    onApplePay: startApplePay
                )


            }
            .padding([.horizontal, .bottom])
        }
    }
    
    private var itemTotal: Double {
        cartManager.cartItems.reduce(0.0) {
            $0 + (Double($1.product.price ?? 0) * Double($1.quantity))
        }
    }
    
    private var paymentMethodText: String {
        switch selectedPayment {
        case .cod:
            return "Dobírkou"
        case .card:
            return "Platba kartou"
        case .bankTransfer:
            return "Bankovní převod"
        }
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
        let productTotal = cartManager.cartItems.reduce(0.0) {
            $0 + (Double($1.product.price ?? 0) * Double($1.quantity))
        }
        return productTotal + Double(selectedShipping.price) + Double(selectedPayment.price)
    }

    private var isFormValid: Bool {
        !fullName.isEmpty && !address.isEmpty && !city.isEmpty && !zip.isEmpty && !phone.isEmpty
    }
    
    private var selectedDeliveryOption: DeliveryOption? {
        DeliveryOption.all.first(where: { $0.method == selectedDeliveryMethod })
    }

    private func saveOrderToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var order: [String: Any] = [
            "userId": uid,
            "timestamp": Timestamp(),
            "fullName": fullName,
            "address": address,
            "city": city,
            "zip": zip,
            "phone": phone,

            // ✅ Add these:
            "shippingMethod": selectedShipping.rawValue,
            "shippingPrice": selectedShipping.price,
            "paymentMethod": selectedPayment.rawValue,
            "paymentPrice": selectedPayment.price,

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

        // ✅ If Zásilkovna pickup is selected, attach point info
        if selectedShipping.requiresPickupPoint, let pickup = selectedPickupPoint {
            order["zasilkovnaPickupPoint"] = [
                "name": pickup.name,
                "address": pickup.address,
                "city": pickup.city
            ]
        }

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
        print("📲 Apple Pay button tapped")
        print("🔍 canMakePayments:", PKPaymentAuthorizationController.canMakePayments())
        print("🔍 canMakePayments(usingNetworks):", PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]))

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

        let total = NSDecimalNumber(value: cartTotal)
        print("💰 Apple Pay total: \(total) CZK")
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Bohem Order", amount: total)
        ]

        let newDelegate = ApplePayDelegate {
            Task {
                print("✅ Apple Pay payment authorized — saving order to Firestore")
                await saveOrderToFirestore()
            }
        }

        self.applePayDelegate = newDelegate

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = newDelegate
        controller.present { presented in
            if presented {
                print("✅ Apple Pay sheet presented successfully")
            } else {
                print("❌ Failed to present Apple Pay sheet — check entitlements and capabilities")
            }
        }
    }


    private func preparePaymentSheet() {
        let amountInCents = Int(cartTotal * 100)
        guard !isSubmitting else {
            print("⚠️ Already submitting — ignoring tap")
            return
        }
        isSubmitting = true
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
                      let clientSecret = data["clientSecret"] as? String,
                      let customerId = data["customer"] as? String,
                      let ephemeralKey = data["ephemeralKey"] as? String else {
                    print("❌ Missing Stripe setup info")
                    return
                }
                print("👉 Stripe response:")
                print("clientSecret: \(clientSecret)")
                print("customer: \(customerId)")
                print("ephemeralKey: \(ephemeralKey)")

                print("✅ Stripe data received. Preparing payment sheet...")

                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "Bohem"
                config.applePay = .init(merchantId: "merchant.com.bohem.store", merchantCountryCode: "CZ")
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
                config.style = .automatic
                config.returnURL = "bohem://stripe-redirect"


                DispatchQueue.main.async {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: clientSecret,
                        configuration: config
                    )
                    print("📲 Presenting PaymentSheet")
                    presentPaymentSheet()
                }
            }
    }


    private func presentPaymentSheet() {
        guard let paymentSheet = self.paymentSheet else {
            print("❌ PaymentSheet is nil — aborting")
            return }
        guard let viewController = topViewController() else {
            print("❌ Failed to get top view controller")
            return
        }

        paymentSheet.present(from: viewController) { result in
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
                isSubmitting = false // ✅ ADD THIS

            case .failed(let error):
                print("❌ Payment failed: \(error.localizedDescription)")
                AnalyticsManager.shared.logCustomEvent(name: "payment_result", params: [
                    "status": "failed",
                    "error": error.localizedDescription
                ])
                isSubmitting = false // ✅ ADD THIS
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
