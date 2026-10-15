//
//  CameraManager.swift
//  FitShop
//

import UIKit
import SwiftUI

// This wrapper lets SwiftUI present the system camera or photo library.
struct CameraManager: UIViewControllerRepresentable {

    // This binding sends the selected image back to the SwiftUI view.
    @Binding var selectedImage: UIImage?

    // This value decides whether the picker opens the camera or the photo library.
    var selectedSource: UIImagePickerController.SourceType

    @Environment(\.dismiss) var dismiss

    // This function creates the UIKit image picker.
    func makeUIViewController(context: Context) -> some UIViewController {
        let myPicker = UIImagePickerController()
        myPicker.sourceType = selectedSource
        myPicker.delegate = context.coordinator
        return myPicker
    }

    // This function is required by the protocol.
    // No live updates are needed here after the picker is created.
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    // This function creates the coordinator that handles picker delegate events.
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        // This reference lets the coordinator update the SwiftUI parent view.
        var parent: CameraManager

        // This initializer saves the parent wrapper.
        init(parent: CameraManager) {
            self.parent = parent
        }

        // This function gets the selected image and closes the picker.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

            if let anImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = anImage
                parent.dismiss()
            }
        }

        // This function closes the picker when the user taps cancel.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

    }

}
