//
//  CartView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CartView: View {

    // This value checks whether the current user is a guest.
    var isGuest: Bool

    // This local guest id lets a guest user keep cart data during the session.
    @AppStorage("guestUserID") var guestUserID = ""

    // These states store cart data, messages, and sheet/dialog control.
    @State private var listCart: [CartItem] = []
    @State var message = ""
    @State private var myListener: FirebaseFirestore.ListenerRegistration?
    @State var selectedItem: CartItem?
    @State var isCheckout = false

    var db = Firestore.firestore()

    // This binding updates the cart badge shown in ContentView.
    @Binding var cartItemCount: Int

    // This computed property calculates the full cart total.
    var totalPrice: Double {
        var total = 0.0

        for oneItem in listCart {
            total = total + (oneItem.price * Double(oneItem.quantity))
        }

        return total
    }

    // This computed property calculates the total number of pieces in the cart.
    var totalItemCount: Int {
        var count = 0

        for oneItem in listCart {
            count = count + oneItem.quantity
        }

        return count
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {
                if listCart.isEmpty {
                    Spacer()
                    Text("Your cart is empty")
                        .foregroundStyle(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(listCart) { oneItem in

                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: oneItem.image)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                } placeholder: {
                                    ProgressView()
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(oneItem.title)")
                                        .lineLimit(2)
                                    Text(String(format: "AED%.2f", oneItem.price))
                                        .foregroundStyle(.orange)
                                }
                                .font(.system(size: 14))

                                Spacer()

                                HStack(spacing: 10) {
                                    Button {
                                        decreaseQuantity(for: oneItem)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(oneItem.quantity <= 1 ? .gray : .orange)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(oneItem.quantity <= 1)

                                    Text("\(oneItem.quantity)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(minWidth: 22)

                                    Button {
                                        increaseQuantity(for: oneItem)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(.orange)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) {
                                    selectedItem = oneItem
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }

                        }
                    }
                    .listStyle(.plain)
                }

                VStack {

                    HStack {
                        Text("Total:")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Text(String(format: "AED%.2f", totalPrice))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal)

                    if isGuest {
                        Text("Login to proceed to checkout")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .padding(.bottom, 4)
                    }

                    Text("\(message)")
                        .foregroundStyle(.green)
                        .padding(.bottom)

                }
                .padding(.top, 8)
            }
            .onAppear() {
                if isGuest && guestUserID.isEmpty {
                    guestUserID = UUID().uuidString
                }
                readLiveCart()
            }
            .onDisappear() {
                stopReadLiveCart()
            }
            .navigationTitle("My Cart")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Checkout") {
                        isCheckout = true
                    }
                    .disabled(isGuest || listCart.isEmpty)
                    .foregroundStyle(isGuest ? .gray : .orange)
                }
            }
            .sheet(isPresented: $isCheckout) {
                NavigationStack {
                    CheckoutView(totalPrice: totalPrice, cartItems: listCart)
                }
            }
            .confirmationDialog("Are you sure you want to delete this item?", isPresented: Binding(
                get: { selectedItem != nil },
                set: { if !$0 { selectedItem = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let selectedItem = selectedItem {
                        deleteCartItem(aItem: selectedItem)
                    }
                }
                Button("Cancel") { }
            }

        }

    }

    // This function reads the current user's cart and listens for live Firestore updates.
    func readLiveCart() {

        let userID = isGuest ? guestUserID : (Auth.auth().currentUser?.uid ?? "")

        if userID.isEmpty {
            message = "Unable to load cart items"
            return
        }

        myListener = db.collection("CartCollection")
            .whereField("userID", isEqualTo: userID)
            .addSnapshotListener({ mySnap, myError in

                if let myError = myError {
                    self.message = myError.localizedDescription
                    return
                }

                if let mySnap = mySnap {
                    listCart = mySnap.documents.compactMap { document in
                        try? document.data(as: CartItem.self)
                    }

                    cartItemCount = totalItemCount
                }

            })

    }

    // This function removes the Firestore listener when the view disappears.
    func stopReadLiveCart() {
        myListener?.remove()
    }

    // This function increases the quantity of one cart item in Firestore.
    func increaseQuantity(for item: CartItem) {

        guard let id = item.id else {
            message = "Update Impossible: No Id"
            return
        }

        db.collection("CartCollection").document(id).updateData([
            "quantity": FieldValue.increment(Int64(1))
        ]) { myError in

            if let myError = myError {
                message = myError.localizedDescription
            } else {
                // The live listener in readLiveCart() updates the badge count.
                message = "Quantity updated successfully"
            }

        }

    }

    // This function decreases the quantity of one cart item in Firestore.
    func decreaseQuantity(for item: CartItem) {

        guard item.quantity > 1 else {
            return
        }

        guard let id = item.id else {
            message = "Update Impossible: No Id"
            return
        }

        db.collection("CartCollection").document(id).updateData([
            "quantity": FieldValue.increment(Int64(-1))
        ]) { myError in

            if let myError = myError {
                message = myError.localizedDescription
            } else {
                // The live listener in readLiveCart() updates the badge count.
                message = "Quantity updated successfully"
            }

        }

    }

    // This function deletes one cart item from Firestore.
    func deleteCartItem(aItem: CartItem) {

        if let id = aItem.id {
            db.collection("CartCollection").document(id).delete { myError in

                if let myError = myError {
                    message = myError.localizedDescription
                } else {
                    // The live listener in readLiveCart() updates the badge count.
                    message = "Item Deleted Successfully"
                }

            }
        } else {
            message = "No Id: Delete Impossible"
        }

    }

}

#Preview {
    @Previewable @State var cartCount = 0
    CartView(isGuest: false, cartItemCount: $cartCount)
}
