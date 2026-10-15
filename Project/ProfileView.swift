//
//  ProfileView.swift
//  FitShop
//

import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    // These bindings update the app login state in ContentView.
    @Binding var isLoggedIn: Bool
    @Binding var isGuest: Bool

    // These states control the profile image, sheets, and status messages.
    @State var myImage: UIImage?
    @State var isCamera = false
    @State var isGallery = false
    @State var message = ""
    @State var myProfile: Profile?
    @State var isEdit = false
    @State var isSettings = false
    @State var isOrderHistory = false

    var db = Firestore.firestore()

    var body: some View {

        NavigationStack {

            VStack {

                if let myImage = myImage {
                    Image(uiImage: myImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundStyle(.gray)
                }

                HStack {
                    Button("Camera") {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            isCamera = true
                        } else {
                            message = "Camera is not available on this device"
                        }
                    }
                    .disabled(isGuest)

                    Button("Gallery") {
                        isGallery = true
                    }
                    .disabled(isGuest)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .font(.system(size: 20))

                if myImage != nil && !isGuest {
                    Button("Save Photo") {
                        savePhotoToFirestore()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .font(.system(size: 18))
                    .padding(.top, 4)
                }

                if let myProfile = myProfile {
                    Form {
                        Section("Profile") {
                            Text("First Name: \(myProfile.firstName)")
                            Text("Last Name: \(myProfile.lastName)")
                            Text("City: \(myProfile.City)")
                            Text("Phone: \(myProfile.phone)")
                            Text("Address: \(myProfile.address)")
                            Text("Email: \(Auth.auth().currentUser?.email ?? "")")
                        }

                        Section("Orders") {
                            Button("View Order History") {
                                isOrderHistory = true
                            }
                        }
                    }
                } else {
                    if isGuest {
                        Text("Browsing as Guest")
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        ProgressView("Loading profile...")
                            .padding()
                    }
                }

                Text("\(message)")
                    .foregroundStyle(.green)
                    .padding()

                Button("Sign Out") {
                    signOutUser()
                }
                .foregroundStyle(.red)
                .font(.system(size: 20))
                .padding()

            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEdit = true
                    }
                    .disabled(isGuest || myProfile == nil)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .onAppear() {
                if !isGuest {
                    loadProfile()
                } else {
                    myProfile = nil
                    myImage = nil
                    message = "Guest users can browse products, but profile editing needs login"
                }
            }
            .sheet(isPresented: $isCamera) {
                CameraManager(selectedImage: $myImage, selectedSource: .camera)
            }
            .sheet(isPresented: $isGallery) {
                CameraManager(selectedImage: $myImage, selectedSource: .photoLibrary)
            }
            .sheet(isPresented: $isEdit, onDismiss: {
                if !isGuest {
                    loadProfile()
                }
            }) {
                if let myProfile = myProfile {
                    EditProfileView(myProfile: myProfile)
                }
            }
            .sheet(isPresented: $isSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .sheet(isPresented: $isOrderHistory) {
                NavigationStack {
                    OrderHistoryView()
                }
            }

        }

    }

    // This function loads the current user's profile from Firestore.
    func loadProfile() {

        guard let currentUser = Auth.auth().currentUser else { return }

        db.collection("ProfilesColl").document(currentUser.uid)
            .getDocument { mySnap, myError in

                if let myError = myError {
                    message = myError.localizedDescription
                    return
                }

                if let mySnap = mySnap, mySnap.exists {
                    myProfile = try? mySnap.data(as: Profile.self)

                    if let base64 = myProfile?.photoBase64, !base64.isEmpty {
                        if let imageData = Data(base64Encoded: base64) {
                            myImage = UIImage(data: imageData)
                        }
                    }
                } else {
                    message = "Profile not found"
                }

            }

    }

    // This function converts the selected image to Base64 and saves it in Firestore.
    func savePhotoToFirestore() {

        guard let currentUser = Auth.auth().currentUser else {
            message = "Please login first"
            return
        }

        guard let myImage = myImage else { return }

        // The photo is resized first so the Base64 text stays far below Firestore's 1 MB document limit.
        guard let imageData = resizedImage(myImage, maxSide: 600).jpegData(compressionQuality: 0.5) else { return }

        let base64String = imageData.base64EncodedString()

        db.collection("ProfilesColl").document(currentUser.uid).updateData([
            "photoBase64": base64String
        ]) { myError in

            if let myError = myError {
                message = myError.localizedDescription
            } else {
                message = "Profile photo saved successfully"
            }

        }

    }

    // This function shrinks an image so its longest side is at most maxSide points.
    // Smaller photos are returned unchanged.
    func resizedImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {

        let longestSide = max(image.size.width, image.size.height)

        if longestSide <= maxSide {
            return image
        }

        let scale = maxSide / longestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

    }

    // This function signs the user out and returns the app to the login screen.
    func signOutUser() {

        if isGuest {
            isGuest = false
            isLoggedIn = false
            return
        }

        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            isGuest = false
        } catch {
            message = "Error signing out"
        }

    }

}

#Preview {
    @Previewable @State var isLoggedIn = true
    @Previewable @State var isGuest = false
    ProfileView(isLoggedIn: $isLoggedIn, isGuest: $isGuest)
}
