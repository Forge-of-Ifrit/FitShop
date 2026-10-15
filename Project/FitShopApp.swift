//
//  FitShopApp.swift
//  FitShop
//

import SwiftUI
import FirebaseCore

@main
struct FitShopApp: App {

    // This initializer starts Firebase once when the app launches.
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

}
