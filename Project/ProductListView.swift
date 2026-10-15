//
//  ProductListView.swift
//  FitShop
//

import SwiftUI

struct ProductListView: View {

    // This value checks whether the current user is a guest.
    var isGuest: Bool

    // This closure lets the parent screen update the cart badge.
    var onItemAddedToCart: (Int) -> Void = { _ in }

    // These states control product data, loading, and category filtering.
    @State var myProducts: [Product] = []
    @State var message = ""
    @State var isLoading = false
    @State var isSearch = false
    @State var selectedCategory = "All"

    // This computed property hides products that belong to the Apparel category.
    var visibleProducts: [Product] {
        myProducts.filter {
            $0.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "apparel"
        }
    }

    // This computed property builds the category list directly from the JSON data.
    var categoryList: [String] {
        let allCategories = visibleProducts.map { $0.category.trimmingCharacters(in: .whitespacesAndNewlines) }
        let uniqueCategories = Array(Set(allCategories)).sorted()
        return ["All"] + uniqueCategories
    }

    // This computed property returns only the products that match the selected category.
    var filteredProducts: [Product] {
        if selectedCategory == "All" {
            return visibleProducts
        } else {
            return visibleProducts.filter {
                $0.category.trimmingCharacters(in: .whitespacesAndNewlines) == selectedCategory
            }
        }
    }

    var body: some View {

        NavigationStack {
            VStack(spacing: 0) {

                if isLoading {
                    ProgressView("Loading products...")
                        .padding(.top)
                }

                if !message.isEmpty {
                    Text(message)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerSection
                        categoriesSection

                        Text("Products")
                            .font(.title3)
                            .fontWeight(.bold)

                        productGridSection
                    }
                    .padding()
                }
                .onAppear {
                    if myProducts.isEmpty {
                        loadProducts()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $isSearch) {
                NavigationStack {
                    SearchProductView(isGuest: isGuest)
                }
            }
        }
    }

    // This section shows the page title and subtitle.
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FitShop")
                .font(.largeTitle)
                .bold()

            Text("Your Fitness Shopping Destination.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // This section shows the categories in a horizontal scroll view.
    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categoryList, id: \.self) { oneCategory in
                        Button {
                            selectedCategory = oneCategory
                        } label: {
                            VStack(spacing: 8) {
                                if oneCategory == "All" {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.orange.opacity(0.12))
                                            .frame(width: 70, height: 70)

                                        Image(systemName: "square.grid.2x2.fill")
                                            .font(.title2)
                                            .foregroundStyle(.orange)
                                    }
                                } else {
                                    Image(assetName(for: oneCategory))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }

                                Text(oneCategory)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(selectedCategory == oneCategory ? Color.orange.opacity(0.15) : Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }
    }

    // This section shows all filtered products in a two-column grid.
    var productGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredProducts) { oneProduct in
                NavigationLink(destination: ProductDetailView(myProduct: oneProduct, isGuest: isGuest, onItemAddedToCart: onItemAddedToCart)) {
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: URL(string: oneProduct.image)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } placeholder: {
                            ProgressView()
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(oneProduct.title)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(2)
                                .frame(minHeight: 32, alignment: .topLeading)

                            Text(oneProduct.category)
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                                .lineLimit(1)

                            Text(String(format: "AED%.2f", oneProduct.price))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.orange)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .foregroundStyle(.primary)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
            }
        }
    }

    // This function returns the correct local asset name for each category card.
    func assetName(for category: String) -> String {
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if cleanCategory == "electronics" {
            return "categoryElectronics"
        } else if cleanCategory == "equipment" {
            return "categoryEquipment"
        } else if cleanCategory == "supplements" {
            return "categorySupplements"
        } else {
            return "categoryAccessories"
        }
    }

    // This function loads the product list from the JSON endpoint.
    func loadProducts() {

        isLoading = true
        message = ""

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
                            myProducts = try myDecoder.decode([Product].self, from: myData)

                            if myProducts.isEmpty {
                                message = "No products available"
                            } else {
                                message = ""
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
    ProductListView(isGuest: false)
}
