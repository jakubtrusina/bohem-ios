import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PassKit

struct CheckoutView: View {
    // MARK: - States
    @State private var fullName = ""
    @State private var address = ""
    @State private var city = ""
    @State private var zip = ""
    @State private var phone = ""
    @State private var isSubmitting = false
    @State private var orderSubmitted = false
    @State private var applePayDelegate: ApplePayDelegate? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var isLaunchingApplePay = false

    
    @ObservedObject var cartManager = CartManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    Text("Shipping Info").font(.headline)
                    TextField("Full Name", text: $fullName)
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("ZIP", text: $zip)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Divider()

                Group {
                    Text("Order Summary").font(.headline)
                    ForEach(cartManager.cartItems, id: \.id) { item in
                        VStack(alignment: .leading) {
                            Text(item.product.title ?? "")
                            Text("Size: \(item.size) | Qty: \(item.quantity)")
                            Text(String(format: "$%.2f", Double(item.product.price ?? 0)))
                        }
                    }

                    Text("Total: CZK\(cartTotal, specifier: "%.2f")")
                        .font(.headline)
                }

                Divider()

                if orderSubmitted {
                    Text("✅ Order Submitted!")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                } else {
                    Button(action: submitOrder) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Order")
                        }
                    }
                    .disabled(fullName.isEmpty || address.isEmpty || city.isEmpty || zip.isEmpty)

                    ZStack {
                        ApplePayButton()
                            .frame(height: 44)

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isLaunchingApplePay else {
                                    print("🟡 Apple Pay already launching")
                                    return
                                }

                                isLaunchingApplePay = true
                                print("🟢 Apple Pay button tapped")
                                startApplePay()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isLaunchingApplePay = false
                                }
                            }
                    }

                }
            }
            .padding()
        }
        .navigationTitle("Checkout")
    }

    
    // MARK: - Cart Total
    private var cartTotal: Double {
        let total = cartManager.cartItems.reduce(0.0) {
            let price = Double($1.product.price ?? 0)
            let quantity = Double($1.quantity)
            return $0 + (price * quantity)
        }
        
        print("🧮 Calculated cartTotal: \(total)")
        return total.isFinite ? total : 0.0
    }
    
    // MARK: - Submit Order
    func submitOrder() {
        isSubmitting = true
        Task {
            await saveOrderToFirestore()
            isSubmitting = false
        }
    }
    
    func saveOrderToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let order: [String: Any] = [
            "userId": uid,
            "timestamp": Timestamp(),
            "fullName": fullName,
            "address": address,
            "city": city,
            "zip": zip,
            "phone": phone,
            "items": cartManager.cartItems.map { [
                "title": $0.product.title ?? "",
                "id": $0.product.id,
                "size": $0.size,
                "quantity": $0.quantity,
                "price": $0.product.price ?? 0
            ]},
            "total": cartTotal
        ]
        
        do {
            try await Firestore.firestore()
                .collection("orders")
                .addDocument(data: order)
            orderSubmitted = true
        } catch {
            print("❌ Failed to save order:", error)
        }
    }
    
    // MARK: - Start Apple Pay
    func startApplePay() {
        print("🧮 cartTotal: \(cartTotal)")
        assert(cartTotal.isFinite, "❌ cartTotal is NaN or Infinite — Apple Pay will fail")

        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("❌ Apple Pay is not available on this device.")
            return
        }

        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex]) else {
            print("❌ Apple Pay is not set up with any supported card.")
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
            if presented {
                print("✅ Apple Pay sheet is showing")
            } else {
                print("❌ Failed to present Apple Pay sheet")
            }
        }
    }

    
    
    // MARK: - Apple Pay Delegate
    class ApplePayDelegate: NSObject, PKPaymentAuthorizationControllerDelegate {
        let onSuccess: () -> Void
        
        init(onSuccess: @escaping () -> Void) {
            self.onSuccess = onSuccess
        }
        
        func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            print("✅ Apple Pay Success:", payment.token.transactionIdentifier)
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            onSuccess()
        }
        
        func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
            print("🔚 Apple Pay flow completed")
            controller.dismiss()
        }
    }
    
    
    // MARK: - Apple Pay SwiftUI Button Wrapper
    struct ApplePayButton: UIViewRepresentable {
        func makeUIView(context: Context) -> PKPaymentButton {
            return PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .black)
        }
        
        func updateUIView(_ uiView: PKPaymentButton, context: Context) {}
    }
}
