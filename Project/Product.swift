//
//  Product.swift
//  FitShop
//

import Foundation

// This URL is the JSON endpoint used to load the product list.
let productsURLString = "https://32171ce925de46009a30e6f7007930d7.api.mockbin.io/"

// This model represents one product from the JSON file.
struct Product: Codable, Identifiable {

    // The product id is used by SwiftUI lists and detail pages.
    let id: Int
    var title: String
    var price: Double
    var description: String
    var category: String
    var image: String

    enum CodingKeys: String, CodingKey {
        case id, title, price, description, category, image
    }

}
