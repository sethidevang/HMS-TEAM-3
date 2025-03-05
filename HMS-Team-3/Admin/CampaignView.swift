//
//  CampaignView.swift
//  HMS-Team-3
//
//  Created by DIWAKAR KUMAR on 20/02/25.
//

import SwiftUI
import SwiftUI
import UIKit

struct RectangleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: RectangleImagePicker
        
        init(_ parent: RectangleImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
    }
}

struct RectangleImageSelector: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var showActionSheet: Bool
    @Binding var sourceType: UIImagePickerController.SourceType
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(12)
            } else {
                Button(action: {
                    showActionSheet = true
                }) {
                    Text("Select Image")
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Select Image Source"), buttons: [
                .default(Text("Photo Library")) {
                    sourceType = .photoLibrary
                    showImagePicker = true
                },
                .default(Text("Camera")) {
                    sourceType = .camera
                    showImagePicker = true
                },
                .cancel()
            ])
        }
    }
}
struct CampaignView: View {
    @State private var campaigns: [Campaign] = [
        Campaign(title: "360° Healthcare", description: "Comprehensive health check-up and inpatient care.", imageUrl: "campaign1", validUntil: "Jun 10, 2024", dateAdded: Date()),
        Campaign(title: "Wellness Program", description: "Join our community wellness initiative for a healthier future.", imageUrl: "campaign2", validUntil: "Dec 31, 2024", dateAdded: Date().addingTimeInterval(-86400))
    ]
    @State private var isPresentingAddCampaign = false
    
    var sortedCampaigns: [Campaign] {
        campaigns.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    var body: some View {
            NavigationStack {
                ZStack {
                    Color(.systemGray6) // ✅ Background applied
                        .edgesIgnoringSafeArea(.all)

                    ScrollView {
                        VStack(spacing: 15) { // ✅ Adds space between campaign cards
                            ForEach(sortedCampaigns) { campaign in
                                CampaignCard(campaign: campaign)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                .navigationTitle("Campaigns")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isPresentingAddCampaign = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isPresentingAddCampaign) {
                    AddCampaignView(campaigns: $campaigns)
                }
            }
        }
}

import SwiftUI
import UIKit

struct AddCampaignView: View {
    @Binding var campaigns: [Campaign]
    @State private var campaignTitle: String = ""
    @State private var description: String = ""
    @State private var validUntil = Date()
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    private var isFormValid: Bool {
        return !campaignTitle.isEmpty && !description.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground) // ✅ Ensures background is correct
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Campaign Title
                        Text("Campaign Title")
                            .font(.headline)
                        TextField("Enter Title", text: $campaignTitle)
                            .padding()
                            .background(Color(.secondarySystemBackground)) // ✅ Proper contrast
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        
                        // Description
                        Text("Description")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(6)
                                .background(Color(.secondarySystemBackground)) // ✅ Better contrast
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            
                            if description.isEmpty {
                                Text("Write Description here")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 10)
                                    .padding(.top, 12)
                                    .allowsHitTesting(false) // ✅ Ensures tap doesn't block input
                            }
                        }
                        
                        // Image Selection
                        HStack {
                            Text("Select Image")
                                .font(.headline)
                            
                            Spacer()
                            
                            RectangleImageSelector(selectedImage: $selectedImage, showImagePicker: $showImagePicker, showActionSheet: $showActionSheet, sourceType: $sourceType)
                                
                        }
                        .padding()
                        .background(Color(.systemBackground)) // ✅ Ensures proper contrast
                        .cornerRadius(10)
                        
                        // Date Picker
                        HStack {
                            Text("Valid Upto")
                                .font(.headline)
                            Spacer()
                            DatePicker("", selection: $validUntil, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding()
                        .background(Color(.systemBackground)) // ✅ Ensures proper contrast
                        .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveCampaign()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
        }
    }
    
    func saveCampaign() {
        let newCampaign = Campaign(
            title: campaignTitle,
            description: description,
            imageUrl: "",
            validUntil: DateFormatter.localizedString(from: validUntil, dateStyle: .medium, timeStyle: .none),
            dateAdded: Date()
        )
        campaigns.append(newCampaign)
        presentationMode.wrappedValue.dismiss()
    }
}
struct CampaignCard: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !campaign.imageUrl.isEmpty {
                Image(campaign.imageUrl)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .cornerRadius(12)
            }
            
            Text(campaign.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(campaign.description)
                .font(.body)
                .foregroundColor(.gray)

            HStack {
                Text("Valid Until:")
                    .fontWeight(.semibold)
                Text(campaign.validUntil)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.systemBackground)) // ✅ Ensures contrast in dark mode
        .cornerRadius(16)
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct Campaign: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageUrl: String
    let validUntil: String
    let dateAdded: Date
}

#Preview {
    CampaignView()
        .preferredColorScheme(.dark)
}
