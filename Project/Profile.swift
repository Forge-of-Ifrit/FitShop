//
//  Profile.swift
//  FitShop
//

import FirebaseFirestore

// This model stores the user profile data in Firestore.
struct Profile: Codable, Identifiable {

    // Firestore fills this document id automatically when the profile is read.
    @DocumentID var id: String?
    var firstName: String
    var lastName: String
    var City: String
    var phone: String
    var address: String
    var userID: String
    var photoBase64: String

}
