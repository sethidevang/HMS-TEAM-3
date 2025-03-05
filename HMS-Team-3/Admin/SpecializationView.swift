//
//  SpecializationView.swift
//  HMS-Team-3
//
//  Created by DIWAKAR KUMAR on 20/02/25.
//

import SwiftUI
import FirebaseFirestore

//struct Specialization: Identifiable {
//    let id: String
//    let name: String
//    let description: String
//}

struct SpecializationView: View {
    @State private var specializations: [SpecializationModel] = []
    @State private var isPresentingAddSpecialization = false
    var hospitalId : String
    var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 12) { // ✅ Adds spacing between elements
                        ForEach(specializations) { specialization in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(specialization.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(specialization.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                            .background(Color(.systemBackground)) // ✅ Card-like background
                            .cornerRadius(16)
                            .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal) // ✅ Adds horizontal spacing
                        }
                    }
                    .padding(.vertical) // ✅ Ensures some space at the top and bottom
                }
                .background(Color(.systemGray6)) // ✅ Light gray background
                
                .navigationTitle("Specialization")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isPresentingAddSpecialization = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isPresentingAddSpecialization) {
                    AddSpecializationView(specializations: $specializations, hospitalId: hospitalId)
                }
                .onAppear {
                    fetchSpecializations()
                }
            }
        }
    
    /// Fetch data from Firestore
    func fetchSpecializations() {
        let db = Firestore.firestore()
        db.collection("specializations").order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching specializations: \(error.localizedDescription)")
                    return
                }

                self.specializations = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String else {
                        return nil
                    }

                    return SpecializationModel(id: doc.documentID, name: name, description: description)
                } ?? []
            }
    }

    
    /// Delete specialization from Firestore
    func deleteSpecialization(at offsets: IndexSet) {
        let db = Firestore.firestore()
        
        offsets.forEach { index in
            let specialization = specializations[index]
            db.collection("specializations").document(specialization.id).delete { error in
                if let error = error {
                    print("Error deleting specialization: \(error.localizedDescription)")
                } else {
                    print("Specialization deleted successfully!")
                }
            }
        }
        
        specializations.remove(atOffsets: offsets)
    }
}

struct AddSpecializationView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var specializations: [SpecializationModel]
    @State private var specializationName: String = ""
    @State private var description: String = ""
    @Environment(\.presentationMode) var presentationMode
    var hospitalId : String
    private var isFormValid: Bool {
        return !specializationName.isEmpty && !description.isEmpty
    }
    
    var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Specialisation Name")
                        .font(.headline)
                    
                    TextField("Enter Specialisation", text: $specializationName)
                        .padding()
                        .background(colorScheme == .dark ? Color.black : Color.white) // ✅ Dynamic Color
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    
                    Text("Description")
                        .font(.headline)
                    
                    ZStack {
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(6)
                            .background(colorScheme == .dark ? Color.black : Color.white) // ✅ Dynamic Color
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        
                        if description.isEmpty {
                            Text("Write description here")
                                .foregroundColor(.gray)
//                                .padding(.leading, 12)
//                                .padding(.top, 12)
                                .allowsHitTesting(false) // ✅ Prevents blocking input
//                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGroupedBackground)) // ✅ Keeps systemGroupedBackground
                .navigationTitle("Add Specialization")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveSpecialization()
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
        }

    
    /// Save new specialization to Firestore
    func saveSpecialization() {
        let db = Firestore.firestore()
        
        let specializationData: [String: Any] = [
            "name": specializationName,
            "description": description,
            "createdAt": Timestamp(date: Date()),
            "hospitalId" : hospitalId
        ]
        
        db.collection("specializations").addDocument(data: specializationData) { error in
            if let error = error {
                print("Error adding specialization: \(error.localizedDescription)")
            } else {
                print("Specialization added successfully!")
                fetchUpdatedSpecializations()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    /// Fetch updated list after adding specialization
    func fetchUpdatedSpecializations() {
        let db = Firestore.firestore()
        db.collection("specializations").order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching updated specializations: \(error.localizedDescription)")
                    return
                }

                self.specializations = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String else { return nil }
                    
                    return SpecializationModel(id: doc.documentID, name: name, description: description)
                } ?? []
            }
    }

}

#Preview {
    SpecializationView(hospitalId: "96")
        .preferredColorScheme(.dark)
}
