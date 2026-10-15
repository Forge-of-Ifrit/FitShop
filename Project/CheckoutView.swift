//
//  CheckoutView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CheckoutView: View {

    // These values come from CartView when the user opens checkout.
    var totalPrice: Double
    var cartItems: [CartItem]

    // These states store the delivery and payment form values.
    @State var fullName = ""
    @State var address = ""
    @State var city = ""
    @State var country = ""
    @State var cardNumber = ""
    @State var expiryDate = Date()
    @State var cvv = ""

    // These states control messages and the confirmation alert.
    @State var message = ""
    @State var isConfirmed = false

    @Environment(\.dismiss) var dismiss

    // This value saves the selected appearance mode on the device.
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var db = Firestore.firestore()

    // This computed property counts the total number of pieces in the order.
    var totalItems: Int {
        var total = 0

        for oneItem in cartItems {
            total = total + oneItem.quantity
        }

        return total
    }

    var body: some View {

        Form {

            Section("Delivery") {
                TextField("Full Name", text: $fullName)
                TextField("Address", text: $address)
                TextField("City", text: $city)
                TextField("Country", text: $country)
            }

            Section("Payment") {
                TextField("Card Number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .onChange(of: cardNumber) { newValue in
                        cardNumber = formatCardNumber(newValue)
                    }

                DatePicker("Expiry Date", selection: $expiryDate, in: Date()..., displayedComponents: .date)

                TextField("CVV", text: $cvv)
                    .keyboardType(.numberPad)
                    .onChange(of: cvv) { newValue in
                        cvv = filterDigits(newValue, maxLength: 3)
                    }
            }

            Section("Order Summary") {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(totalItems)")
                }

                HStack {
                    Text("Total")
                    Spacer()
                    Text(String(format: "AED%.2f", totalPrice))
                        .foregroundStyle(.orange)
                        .bold()
                }
            }

            if !message.isEmpty {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Confirm Order") {
                    confirmOrder()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.orange)
            }

        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .alert("Order Confirmed!", isPresented: $isConfirmed) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you \(fullName)! Your order of \(String(format: "AED%.2f", totalPrice)) has been placed successfully.")
        }

    }

    // This function validates the checkout form and saves the order in Firestore.
    func confirmOrder() {

        let cleanFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCardDigits = cardNumber.filter { $0.isNumber }
        let cleanCVV = cvv.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanFullName.isEmpty || cleanAddress.isEmpty || cleanCity.isEmpty || cleanCountry.isEmpty ||
            cleanCardDigits.isEmpty || cleanCVV.isEmpty {
            message = "Please fill in all fields"
            return
        }

        if cleanCardDigits.count != 16 {
            message = "Card number must be 16 digits"
            return
        }

        if cleanCVV.count != 3 {
            message = "CVV must be 3 digits"
            return
        }

        guard let currentUser = Auth.auth().currentUser else {
            message = "Please login first"
            return
        }

        let orderItems = cartItems.map { oneItem in
            OrderItem(
                productId: oneItem.productId,
                title: oneItem.title,
                price: oneItem.price,
                quantity: oneItem.quantity
            )
        }

        let newOrder = Order(
            userID: currentUser.uid,
            fullName: cleanFullName,
            address: cleanAddress,
            city: cleanCity,
            country: cleanCountry,
            totalPrice: totalPrice,
            itemCount: totalItems,
            items: orderItems,
            orderDate: Date()
        )

        do {
            try db.collection("OrdersCollection").addDocument(from: newOrder) { myError in
                if let myError = myError {
                    message = myError.localizedDescription
                } else {
                    clearCartAfterCheckout()
                }
            }
        } catch {
            message = "Error saving order"
        }
    }

    // This function clears the cart after the order is saved.
    func clearCartAfterCheckout() {

        for oneItem in cartItems {
            if let id = oneItem.id {
                db.collection("CartCollection").document(id).delete()
            }
        }

        message = ""
        isConfirmed = true
    }

    // This function keeps only digits and limits the length of numeric input.
    func filterDigits(_ value: String, maxLength: Int) -> String {
        let digits = value.filter { $0.isNumber }
        return String(digits.prefix(maxLength))
    }

    // This function formats the card number in groups of four digits.
    func formatCardNumber(_ value: String) -> String {
        let digits = value.filter { $0.isNumber }
        let limitedDigits = String(digits.prefix(16))
        var result = ""

        for (index, digit) in limitedDigits.enumerated() {
            if index != 0 && index % 4 == 0 {
                result.append(" ")
            }
            result.append(digit)
        }

        return result
    }

}

#Preview {
    NavigationStack {
        CheckoutView(totalPrice: 849.55, cartItems: [])
    }
}
