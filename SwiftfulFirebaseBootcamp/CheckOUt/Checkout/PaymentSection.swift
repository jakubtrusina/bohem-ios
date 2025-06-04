import SwiftUI
import FirebaseAnalytics

struct PaymentSection: View {
    let orderSubmitted: Bool
    let isSubmitting: Bool
    let isFormValid: Bool
    let selectedPayment: PaymentOption
    let onSubmit: () -> Void
    let onCardPay: () -> Void
    let onApplePay: () -> Void

    var body: some View {
        Group {
            if orderSubmitted {
                VStack(spacing: 16) {
                    Text("✅ Objednávka úspěšně odeslána!")
                        .foregroundColor(.green)
                        .font(.title3.bold())

                    Button(action: {
                        Analytics.logEvent("back_to_shop_tapped", parameters: nil)
                    }) {
                        Text("Zpět do obchodu")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    if selectedPayment == .cod {
                        Button(action: {
                            Analytics.logEvent("order_submit_attempted", parameters: [
                                "form_valid": isFormValid
                            ])
                            onSubmit()
                        }) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Odeslat objednávku")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.black : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(!isFormValid || isSubmitting)
                    } else {
                        ApplePayButton {
                            if isFormValid && !isSubmitting {
                                Analytics.logEvent("apple_pay_attempted", parameters: nil)
                                onApplePay()
                            } else {
                                Analytics.logEvent("apple_pay_invalid_attempt", parameters: [
                                    "form_valid": isFormValid,
                                    "is_submitting": isSubmitting
                                ])
                            }
                        }
                        .frame(height: 44)

                        Button(action: {
                            if isFormValid && !isSubmitting {
                                Analytics.logEvent("card_payment_attempted", parameters: nil)
                                onCardPay()
                            } else {
                                Analytics.logEvent("card_payment_invalid_attempt", parameters: [
                                    "form_valid": isFormValid,
                                    "is_submitting": isSubmitting
                                ])
                            }
                        }) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Zaplatit kartou")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.black : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(!isFormValid || isSubmitting)
                    }
                }
            }
        }
        .padding()
    }
}
