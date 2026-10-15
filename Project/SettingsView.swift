//
//  SettingsView.swift
//  FitShop
//

import SwiftUI

struct SettingsView: View {

    // This value saves the selected appearance mode on the device.
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var body: some View {

        Form {

            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.gray)
                }
            }

        }
        .navigationTitle("Settings")
        .preferredColorScheme(isDarkMode ? .dark : .light)

    }

}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
