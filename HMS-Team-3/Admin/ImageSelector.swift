//
//  ImageSelector.swift
//  HMS-Team-3
//
//  Created by Devang Sethi on 17/02/25.
//

import SwiftUI

struct ImageSelector: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var showActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType

    var body: some View {
        VStack {
            Button(action: {
                showActionSheet = true
            }) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                }
            }
            Text("Edit Photo")
                .foregroundColor(.blue)
                .font(.caption)
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Choose Photo"), buttons: [
                .default(Text("Take Photo")) {
                    sourceType = .camera
                    showImagePicker = true
                },
                .default(Text("Choose from Library")) {
                    sourceType = .photoLibrary
                    showImagePicker = true
                },
                .cancel()
            ])
        }
    }
}
