//
//  SignUpView.swift
//  FitShop
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {

    // This state collects all profile values before they are saved to Firestore.
    @State var myProfile = Profile(firstName: "", lastName: "", City: "", phone: "", address: "", userID: "", photoBase64: "")

    // These states store the authentication form values.
    @State var username = ""
    @State var password = ""
    @State var confirmPassword = ""

    // This state shows validation or Firebase messages on screen.
    @State var message = ""

    @Environment(\.dismiss) var dismiss

    // This value saves the selected appearance mode on the device.
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var db = Firestore.firestore()

    var body: some View {

        ScrollView {
            VStack(spacing: 20) {

                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 55))
                        .foregroundStyle(.orange)

                    Text("Create Account")
                        .font(.system(size: 30, weight: .bold))

                    Text("Join FitShop and save your profile details")
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Credentials")
                        .font(.system(size: 22, weight: .semibold))

                    TextField("E-mail", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile")
                        .font(.system(size: 22, weight: .semibold))

                    TextField("First Name", text: $myProfile.firstName)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Last Name", text: $myProfile.lastName)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("City", text: $myProfile.City)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    TextField("Phone Number", text: $myProfile.phone)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: myProfile.phone) { newValue in
                            myProfile.phone = filterDigits(newValue, maxLength: 15)
                        }

                    TextField("Address", text: $myProfile.address)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                if !message.isEmpty {
                    Text(message)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    signUpUser()
                } label: {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Back to Login") {
                    dismiss()
                }
                .foregroundStyle(.orange)
            }
            .padding()
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)

    }

    // This function validates the sign-up form and creates the Firebase user account.
    func signUpUser() {

        let cleanEmail = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        myProfile.firstName = myProfile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        myProfile.lastName = myProfile.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        myProfile.City = myProfile.City.trimmingCharacters(in: .whitespacesAndNewlines)
        myProfile.phone = myProfile.phone.trimmingCharacters(in: .whitespacesAndNewlines)
        myProfile.address = myProfile.address.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanEmail.isEmpty || cleanPassword.isEmpty || cleanConfirmPassword.isEmpty ||
            myProfile.firstName.isEmpty || myProfile.lastName.isEmpty || myProfile.City.isEmpty ||
            myProfile.phone.isEmpty || myProfile.address.isEmpty {
            message = "Please fill in all fields"
            return
        }

        if !cleanEmail.contains("@") || !cleanEmail.contains(".") {
            message = "Please enter a valid email address"
            return
        }

        if cleanPassword.count < 6 {
            message = "Password must be at least 6 characters"
            return
        }

        if cleanPassword != cleanConfirmPassword {
            message = "Password confirmation does not match"
            return
        }

        Auth.auth().createUser(withEmail: cleanEmail, password: cleanPassword) { myResult, myError in

            if let myError = myError {
                message = myError.localizedDescription
                return
            }

            if let currentUser = Auth.auth().currentUser {
                myProfile.userID = currentUser.uid
                createUserDocument(email: cleanEmail)
            }

        }

    }

    // This function creates a simple user document so the project uses a fourth collection.
    func createUserDocument(email: String) {

        guard let currentUser = Auth.auth().currentUser else {
            message = "No authenticated user found"
            return
        }

        db.collection("users").document(currentUser.uid).setData([
            "userID": currentUser.uid,
            "email": email,
            "firstName": myProfile.firstName,
            "lastName": myProfile.lastName,
            "city": myProfile.City,
            "createdAt": Date()
        ]) { myError in

            if let myError = myError {
                message = myError.localizedDescription
            } else {
                createProfile()
            }

        }

    }

    // This function creates the profile document after the user account is created.
    func createProfile() {

        guard let currentUser = Auth.auth().currentUser else {
            message = "No authenticated user found"
            return
        }

        do {
            try db.collection("ProfilesColl").document(currentUser.uid).setData(from: myProfile) { myError in

                if let myError = myError {
                    message = myError.localizedDescription
                    return
                }

                message = "Account created successfully"
                dismiss()

            }
        } catch {
            message = "Error creating the profile"
        }

    }

    // This function keeps only numbers and limits the length of the phone input.
    func filterDigits(_ value: String, maxLength: Int) -> String {
        let digits = value.filter { $0.isNumber }
        return String(digits.prefix(maxLength))
    }

}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
