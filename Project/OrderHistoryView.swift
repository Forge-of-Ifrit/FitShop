//
//  OrderHistoryView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OrderHistoryView: View {

    // These states store the loaded orders and any message shown on screen.
    @State var orders: [Order] = []
    @State var message = ""

    var db = Firestore.firestore()

    var body: some View {

        VStack {
            if !message.isEmpty {
                Text(message)
                    .foregroundStyle(.red)
                    .padding()
            }

            if orders.isEmpty && message.isEmpty {
                Text("No orders yet")
                    .foregroundStyle(.gray)
                    .padding()
            } else {
                List {
                    ForEach(orders) { oneOrder in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(oneOrder.fullName)
                                .font(.headline)

                            Text("Total: \(String(format: "AED%.2f", oneOrder.totalPrice))")
                                .foregroundStyle(.orange)

                            Text("Items: \(oneOrder.itemCount)")
                                .foregroundStyle(.gray)

                            Text("Address: \(oneOrder.city), \(oneOrder.country)")
                                .foregroundStyle(.gray)

                            Text(oneOrder.orderDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.gray)

                            if let items = oneOrder.items, !items.isEmpty {
                                Divider()

                                Text("Receipt Items:")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)

                                ForEach(0..<items.count, id: \.self) { index in
                                    HStack {
                                        Text("\(items[index].title) x\(items[index].quantity)")
                                        Spacer()
                                        Text(String(format: "AED%.2f", items[index].price * Double(items[index].quantity)))
                                    }
                                    .font(.system(size: 14))
                                    .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Order History")
        .onAppear {
            loadOrders()
        }

    }

    // This function loads all orders that belong to the current Firebase user.
    func loadOrders() {
        guard let currentUser = Auth.auth().currentUser else {
            message = "Please login first"
            return
        }

        db.collection("OrdersCollection")
            .whereField("userID", isEqualTo: currentUser.uid)
            .getDocuments { mySnap, myError in

                if let myError = myError {
                    message = myError.localizedDescription
                    return
                }

                if let mySnap = mySnap {
                    let loadedOrders = mySnap.documents.compactMap {
                        try? $0.data(as: Order.self)
                    }

                    orders = loadedOrders.sorted {
                        $0.orderDate > $1.orderDate
                    }

                    if orders.isEmpty {
                        message = ""
                    }
                }
            }
    }

}

#Preview {
    NavigationStack {
        OrderHistoryView()
    }
}
