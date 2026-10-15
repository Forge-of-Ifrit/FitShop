//
//  ProductRowView.swift
//  FitShop
//

import SwiftUI

// This reusable row is used in the product search results.
struct ProductRowView: View {

    // This value holds the product shown inside the row.
    @State var myProduct: Product

    var body: some View {

        HStack {

            AsyncImage(url: URL(string: myProduct.image)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            } placeholder: {
                ProgressView()
            }

            VStack(alignment: .leading) {
                Text("\(myProduct.title)")
                    .lineLimit(2)
                Text("\(myProduct.category)")
                    .foregroundStyle(.gray)
                Text(String(format: "AED%.2f", myProduct.price))
                    .foregroundStyle(.orange)
            }
            .font(.system(size: 14))
            .padding()

        }

    }

}

#Preview {
    @Previewable @State var aProduct = Product(id: 1, title: "", price: 0, description: "", category: "", image: "")
    ProductRowView(myProduct: aProduct)
}
