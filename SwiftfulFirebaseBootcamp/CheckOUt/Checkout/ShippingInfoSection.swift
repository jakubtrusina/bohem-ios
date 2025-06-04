import SwiftUI
import FirebaseAnalytics

struct ShippingInfoSection: View {
    @Binding var fullName: String
    @Binding var address: String
    @Binding var city: String
    @Binding var zip: String
    @Binding var phone: String

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, address, city, zip, phone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                TextField("Celé jméno", text: $fullName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit {
                        Analytics.logEvent("shipping_fullName_updated", parameters: ["value_length": fullName.count])
                        focusedField = .address
                    }

                TextField("Ulice a číslo", text: $address)
                    .textContentType(.fullStreetAddress)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .address)
                    .submitLabel(.next)
                    .onSubmit {
                        Analytics.logEvent("shipping_address_updated", parameters: ["value_length": address.count])
                        focusedField = .city
                    }

                TextField("Město", text: $city)
                    .textContentType(.addressCity)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .city)
                    .submitLabel(.next)
                    .onSubmit {
                        Analytics.logEvent("shipping_city_updated", parameters: ["value_length": city.count])
                        focusedField = .zip
                    }

                TextField("PSČ", text: $zip)
                    .keyboardType(.numbersAndPunctuation)
                    .textContentType(.postalCode)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .zip)
                    .submitLabel(.next)
                    .onSubmit {
                        Analytics.logEvent("shipping_zip_updated", parameters: ["value_length": zip.count])
                        focusedField = .phone
                    }

                TextField("Telefon", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .phone)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(action: {
                                Analytics.logEvent("shipping_phone_updated", parameters: ["value_length": phone.count])
                                focusedField = nil // dismiss
                            }) {
                                Text("Hotovo")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .cornerRadius(8)
                            }
                        }
                    }

            }
        }
        .padding(.top, 4)
        .hideKeyboardOnTap()
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
#endif
