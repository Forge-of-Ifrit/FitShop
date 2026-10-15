//
//  CartItem.swift
//  FitShop
//

import Foundation
import FirebaseFirestore

// This model represents one item saved in the cart collection.
struct CartItem: Codable, Identifiable {

    // Firestore fills this document id automatically when cart items are read.
    @DocumentID var id: String?
    var productId: Int
    var title: String
    var price: Double
    var category: String
    var image: String
    var quantity: Int
    var userID: String

}

// This model stores one product line inside an order receipt.
struct OrderItem: Codable {

    var productId: Int
    var title: String
    var price: Double
    var quantity: Int

}

// This model represents one saved order in Firestore.
struct Order: Codable, Identifiable {

    // Firestore fills this document id automatically when orders are read.
    @DocumentID var id: String?
    var userID: String
    var fullName: String
    var address: String
    var city: String
    var country: String
    var totalPrice: Double
    var itemCount: Int
    var items: [OrderItem]?
    var orderDate: Date

}
