//
//  LoginView.swift
//  FitShop
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {

    // These states store the login form values.
    @State private var email = ""
    @State private var pswd = ""

    // These bindings update the app state in ContentView after login.
    @Binding var isLoggedIn: Bool
    @Binding var isGuest: Bool

    // These states control error and success alerts.
    @State private var errorAuth = false
    @State private var errorMessage = ""
    @State private var isSignUp = false
    @State private var loginSuccess = false

    // This value saves the selected appearance mode on the device.
    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var db = Firestore.firestore()

    var body: some View {

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    VStack(spacing: 12) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 55))
                            .foregroundStyle(.orange)

                        Text("Welcome to FitShop")
                            .font(.system(size: 30, weight: .bold))

                        Text("Login to continue shopping")
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 25)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Login")
                            .font(.system(size: 22, weight: .semibold))

                        VStack(spacing: 14) {
                            TextField("E-mail", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            SecureField("Password", text: $pswd)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            loginUser()
                        } label: {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 14) {
                        Button {
                            isSignUp = true
                        } label: {
                            Text("Create New Account")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            isGuest = true
                            isLoggedIn = true
                        } label: {
                            Text("Continue as Guest")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .alert(isPresented: $errorAuth) {
            Alert(title: Text("Authentication Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Login Successful", isPresented: $loginSuccess) {
            Button("OK") {
                isGuest = false
                isLoggedIn = true
            }
        } message: {
            Text("Welcome back to FitShop")
        }
        .sheet(isPresented: $isSignUp) {
            NavigationStack {
                SignUpView()
            }
        }

    }

    // This function validates the login fields and signs the user in with Firebase Auth.
    func loginUser() {

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = pswd.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanEmail.isEmpty || cleanPassword.isEmpty {
            errorMessage = "Please enter your email and password"
            errorAuth = true
            return
        }

        if !cleanEmail.contains("@") || !cleanEmail.contains(".") {
            errorMessage = "Please enter a valid email address"
            errorAuth = true
            return
        }

        Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword) { myResult, myError in

            if let myError = myError {
                errorMessage = myError.localizedDescription
                errorAuth = true
                return
            }

            createUserDocumentIfNeeded(email: cleanEmail)

        }

    }

    // This function makes sure a Firestore user document exists after login.
    func createUserDocumentIfNeeded(email: String) {

        guard let currentUser = Auth.auth().currentUser else {
            loginSuccess = true
            return
        }

        db.collection("users").document(currentUser.uid).setData([
            "userID": currentUser.uid,
            "email": email
        ], merge: true) { myError in

            if let myError = myError {
                errorMessage = myError.localizedDescription
                errorAuth = true
            } else {
                loginSuccess = true
            }

        }

    }

}

#Preview {
    @Previewable @State var isLoggedIn = false
    @Previewable @State var isGuest = false
    LoginView(isLoggedIn: $isLoggedIn, isGuest: $isGuest)
}
