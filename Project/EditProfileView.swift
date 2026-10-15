//
//  EditProfileView.swift
//  FitShop
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {

    // This state holds the editable profile data shown in the form.
    @State var myProfile: Profile

    // This state shows validation or save messages on screen.
    @State var message = ""

    @Environment(\.dismiss) var dismiss
    var db = Firestore.firestore()

    var body: some View {

        Form {
            Section("Personal Info:") {
                TextField("First Name:", text: $myProfile.firstName)
                TextField("Last Name:", text: $myProfile.lastName)
                TextField("Phone Number:", text: $myProfile.phone)
                    .keyboardType(.phonePad)
            }
            Section("Location:") {
                TextField("City:", text: $myProfile.City)
                TextField("Address:", text: $myProfile.address)
            }
        }

        VStack {

            Text("\(message)")
                .padding()
                .foregroundStyle(.red)

            Button("Save Changes") {
                if myProfile.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    myProfile.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    myProfile.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    myProfile.City.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    myProfile.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    message = "Fill all the mandatory fields"
                } else {
                    updateProfile()
                }
            }
            .font(.system(size: 20))

        }

    }

    // This function saves the edited profile back to Firestore.
    func updateProfile() {

        if let id = myProfile.id {
            do {
                try db.collection("ProfilesColl").document(id).setData(from: myProfile) { myError in

                    if let myError = myError {
                        message = myError.localizedDescription
                    } else {
                        updateUserCollection(id: id)
                    }

                }
            } catch {
                message = "Error updating the profile"
            }
        } else {
            message = "Update Impossible: No Id"
        }

    }

    // This function keeps the users collection updated with basic user information.
    func updateUserCollection(id: String) {

        let currentEmail = Auth.auth().currentUser?.email ?? ""

        db.collection("users").document(id).setData([
            "userID": myProfile.userID,
            "email": currentEmail,
            "firstName": myProfile.firstName,
            "lastName": myProfile.lastName,
            "city": myProfile.City
        ], merge: true) { myError in

            if let myError = myError {
                message = myError.localizedDescription
            } else {
                message = "Profile updated successfully"
                dismiss()
            }

        }

    }

}

#Preview {
    @Previewable @State var aProfile = Profile(firstName: "John", lastName: "Doe", City: "Dubai", phone: "+971501234567", address: "Sheikh Zayed Rd", userID: "", photoBase64: "")
    EditProfileView(myProfile: aProfile)
}
