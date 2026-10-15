//
//  ContentView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {

    // This state checks whether there is already a logged-in Firebase user.
    @State private var isLoggedIn = Auth.auth().currentUser != nil

    // This state tracks whether the user entered the app as a guest.
    @State private var isGuest = false

    // This value saves the selected appearance mode on the device.
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    // This state stores the total number of items shown on the cart badge.
    @State private var cartItemCount: Int = 0

    var body: some View {

        if isLoggedIn {

            TabView {

                ProductListView(isGuest: isGuest, onItemAddedToCart: { addedCount in
                    cartItemCount += addedCount
                })
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }

                CartView(isGuest: isGuest, cartItemCount: $cartItemCount)
                    .tabItem {
                        Label("Cart", systemImage: "cart.fill")
                    }
                    .badge(cartItemCount > 0 ? String(cartItemCount) : nil)

                ProfileView(isLoggedIn: $isLoggedIn, isGuest: $isGuest)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }

            }
            .tint(.orange)
            .preferredColorScheme(isDarkMode ? .dark : .light)

        } else {

            LoginView(isLoggedIn: $isLoggedIn, isGuest: $isGuest)

        }

    }

}

#Preview {
    ContentView()
}
