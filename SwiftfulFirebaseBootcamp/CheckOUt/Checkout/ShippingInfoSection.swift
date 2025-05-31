import SwiftUI
import FirebaseAnalytics

struct ShippingInfoSection: View {
    @Binding var fullName: String
    @Binding var address: String
    @Binding var city: String
    @Binding var zip: String
    @Binding var phone: String

    @State private var fullNameEdited = false
    @State private var addressEdited = false
    @State private var cityEdited = false
    @State private var zipEdited = false
    @State private var phoneEdited = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                TextField("Celé jméno", text: $fullName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !fullNameEdited {
                            Analytics.logEvent("shipping_fullName_updated", parameters: [
                                "value_length": fullName.count
                            ])
                            fullNameEdited = true
                        }
                    }

                TextField("Ulice a číslo", text: $address)
                    .textContentType(.fullStreetAddress)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !addressEdited {
                            Analytics.logEvent("shipping_address_updated", parameters: [
                                "value_length": address.count
                            ])
                            addressEdited = true
                        }
                    }

                TextField("Město", text: $city)
                    .textContentType(.addressCity)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !cityEdited {
                            Analytics.logEvent("shipping_city_updated", parameters: [
                                "value_length": city.count
                            ])
                            cityEdited = true
                        }
                    }

                TextField("PSČ", text: $zip)
                    .keyboardType(.numbersAndPunctuation)
                    .textContentType(.postalCode)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !zipEdited {
                            Analytics.logEvent("shipping_zip_updated", parameters: [
                                "value_length": zip.count
                            ])
                            zipEdited = true
                        }
                    }

                TextField("Telefon", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !phoneEdited {
                            Analytics.logEvent("shipping_phone_updated", parameters: [
                                "value_length": phone.count
                            ])
                            phoneEdited = true
                        }
                    }
            }
        }
        .padding(.top, 4)
    }
}
