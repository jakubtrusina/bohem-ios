//
//  Untitled.swift
//  SwiftfulFirebaseBootcamp
//
//  Created by Jakub Trusina on 5/28/25.
//

import PassKit

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
