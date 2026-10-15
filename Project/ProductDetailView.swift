//
//  ProductDetailView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProductDetailView: View {

    // This state stores the product being shown on the detail page.
    @State var myProduct: Product

    // This value checks whether the current user is a guest.
    var isGuest: Bool

    // This value stores a local guest id so a guest can still use the cart.
    @AppStorage("guestUserID") var guestUserID = ""

    // This state shows cart messages on the screen.
    @State var message = ""

    var db = Firestore.firestore()

    // This closure lets the parent view update the cart badge after an item is added.
    var onItemAddedToCart: (Int) -> Void = { _ in }

    var body: some View {

        VStack {

            AsyncImage(url: URL(string: myProduct.image)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } placeholder: {
                ProgressView()
            }

            VStack(alignment: .leading) {
                Text("\(myProduct.title)")
                    .font(.system(size: 18, weight: .semibold))
                Text("\(myProduct.category)")
                    .foregroundStyle(.gray)
                Text(String(format: "AED%.2f", myProduct.price))
                    .foregroundStyle(.orange)
                    .font(.system(size: 20, weight: .bold))
                Text("\(myProduct.description)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding()

            Text("\(message)")
                .padding()
                .foregroundStyle(.green)

            Button("Add to Cart") {
                addToCart()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .font(.system(size: 20))
            .padding(.horizontal)

            if isGuest {
                Text("Login to Checkout")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundStyle(.gray)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

        }
        .padding()
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if isGuest && guestUserID.isEmpty {
                guestUserID = UUID().uuidString
            }
        }

    }

    // This function adds the selected product to Firestore cart data.
    // If the product already exists in the cart, it increases the quantity instead.
    func addToCart() {

        let userID = isGuest ? guestUserID : (Auth.auth().currentUser?.uid ?? "")

        if userID.isEmpty {
            message = "Unable to identify the current user"
            return
        }

        db.collection("CartCollection")
            .whereField("userID", isEqualTo: userID)
            .whereField("productId", isEqualTo: myProduct.id)
            .getDocuments { mySnap, myError in

                if let myError = myError {
                    message = myError.localizedDescription
                    return
                }

                if let mySnap = mySnap, !mySnap.documents.isEmpty {

                    let docID = mySnap.documents.first!.documentID
                    let currentQty = mySnap.documents.first!.data()["quantity"] as? Int ?? 1

                    db.collection("CartCollection").document(docID).updateData([
                        "quantity": currentQty + 1
                    ]) { myError in

                        if let myError = myError {
                            message = myError.localizedDescription
                        } else {
                            message = "Quantity updated in cart"
                            onItemAddedToCart(1)
                        }

                    }

                } else {

                    let newItem = CartItem(
                        productId: myProduct.id,
                        title: myProduct.title,
                        price: myProduct.price,
                        category: myProduct.category,
                        image: myProduct.image,
                        quantity: 1,
                        userID: userID
                    )

                    do {
                        try db.collection("CartCollection").addDocument(from: newItem)
                        message = "Added to cart successfully"
                        onItemAddedToCart(1)
                    } catch {
                        message = "Error adding to cart"
                    }

                }

            }

    }

}

#Preview {
    @Previewable @State var aProduct = Product(id: 1, title: "Test Product", price: 29.99, description: "A great product", category: "clothing", image: "")
    NavigationStack {
        ProductDetailView(myProduct: aProduct, isGuest: false)
    }
}
