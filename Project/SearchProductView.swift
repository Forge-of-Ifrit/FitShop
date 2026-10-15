//
//  SearchProductView.swift
//  FitShop
//

import SwiftUI

struct SearchProductView: View {

    // This value checks whether the current user is a guest.
    var isGuest: Bool

    // These states store the search text, results, and loading message.
    @State var searchText = ""
    @State var myProducts: [Product] = []
    @State var message = ""
    @State var isLoading = false

    var body: some View {

        List {

            Section {
                TextField("Search products...", text: $searchText)

                Button("Find Product") {
                    let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

                    if !cleanSearch.isEmpty {
                        searchProducts()
                    } else {
                        message = "Please enter a search word"
                        myProducts = []
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Searching...")
                        Spacer()
                    }
                }
            }

            if !message.isEmpty {
                Section {
                    Text(message)
                        .foregroundStyle(.gray)
                }
            }

            Section {
                ForEach(myProducts) { oneProduct in
                    NavigationLink(destination: ProductDetailView(myProduct: oneProduct, isGuest: isGuest)) {
                        ProductRowView(myProduct: oneProduct)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search")
    }

    // This function loads products from JSON and filters them using the search text.
    func searchProducts() {

        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        isLoading = true
        message = ""
        myProducts = []

        if let myURL = URL(string: productsURLString) {

            URLSession.shared.dataTask(with: myURL) { myData, myResponse, myError in

                DispatchQueue.main.async {
                    isLoading = false

                    if let myError = myError {
                        message = myError.localizedDescription
                        return
                    }

                    if let myData = myData {
                        let myDecoder = JSONDecoder()

                        do {
                            let allProducts = try myDecoder.decode([Product].self, from: myData)
                            let filteredProducts = allProducts.filter {
                                $0.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "apparel"
                            }

                            myProducts = filteredProducts.filter {
                                $0.title.localizedCaseInsensitiveContains(cleanSearch) ||
                                $0.category.localizedCaseInsensitiveContains(cleanSearch)
                            }

                            if myProducts.isEmpty {
                                message = "No products found for \"\(cleanSearch)\""
                            } else {
                                message = "\(myProducts.count) product(s) found"
                            }

                        } catch {
                            message = "Error decoding JSON"
                        }
                    } else {
                        message = "No data received from the endpoint"
                    }
                }

            }.resume()

        } else {
            message = "Error creating the URL Object"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        SearchProductView(isGuest: false)
    }
}
