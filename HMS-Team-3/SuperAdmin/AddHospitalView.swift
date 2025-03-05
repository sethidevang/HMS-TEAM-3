import SwiftUI
import FirebaseFirestore
import MapKit

struct AddHospitalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hospital = Hospital(
        name: "",
        location: "",
        admin: Admin(id: "", name: "", email: "", address: "", experience: "", phoneNumber: "")
    )
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showLocationPicker = false

    var isFormValid: Bool {
        !hospital.name.isEmpty &&
        !hospital.location.isEmpty &&
        !hospital.admin.name.isEmpty &&
        !hospital.admin.email.isEmpty &&
        !hospital.admin.address.isEmpty &&
        !hospital.admin.experience.isEmpty &&
        !hospital.admin.phoneNumber.isEmpty &&
        Int(hospital.admin.experience) != nil &&
        isValidPhoneNumber(hospital.admin.phoneNumber)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Hospital Details").font(.headline)) {
                    TextField("Hospital Name", text: $hospital.name)
                    
                    NavigationLink(destination: LocationSearchView(selectedLocation: $hospital.location)) {
                        HStack {
                            Text("Location")
                            Spacer()
                            Text(hospital.location.isEmpty ? "Select Location" : hospital.location)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Admin Details").font(.headline)) {
                    TextField("Full Name", text: $hospital.admin.name)
                    TextField("Email", text: $hospital.admin.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $hospital.admin.address)
                            .frame(minHeight: 50)
                            .foregroundColor(hospital.admin.address.isEmpty ? .gray : .primary)
                        
                        if hospital.admin.address.isEmpty {
                            Text("Enter Address...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 5)
                                .padding(.top, 8)
                        }
                    }
                    
                    TextField("Experience (Years)", text: $hospital.admin.experience)
                        .keyboardType(.numberPad)
                    
                    TextField("Phone Number", text: $hospital.admin.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Add Hospital")
            .navigationBarItems(trailing: Button(action: saveHospitalDetails) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Done")
                        .foregroundColor(isFormValid ? .blue : .gray)
                }
            }
            .disabled(!isFormValid || isSaving))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Input"), message: Text(errorMessage ?? "All fields are required."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func saveHospitalDetails() {
        guard isFormValid else {
            errorMessage = "All fields are required, and Experience & Phone Number must be valid."
            showAlert = true
            return
        }
        
        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let hospitalRef = db.collection("hospitals").document() // Firestore auto-generated ID
        let hospitalId = hospitalRef.documentID
        let adminId = UUID().uuidString
        
        // Generate Admin Password
        let lastFourDigits = String(hospital.admin.phoneNumber.suffix(4))
        let adminPassword = hospital.admin.name.replacingOccurrences(of: " ", with: "") + lastFourDigits

        let hospitalData: [String: Any] = [
            "id": hospitalId,
            "name": hospital.name,
            "location": hospital.location,
            "admin": [
                "HospitalId": hospitalId,
                "id": adminId,
                "name": hospital.admin.name,
                "email": hospital.admin.email,
                "address": hospital.admin.address,
                "experience": hospital.admin.experience,
                "phoneNumber": hospital.admin.phoneNumber,
                "passwordGenerated": true
            ]
        ]

        let adminCredentials: [String: Any] = [
            "email": hospital.admin.email,
            "password": adminPassword,
            "HospitalID": hospitalId
        ]

        // Save Admin Credentials
        db.collection("admin_credentials").document(adminId).setData(adminCredentials) { error in
            if let error = error {
                isSaving = false
                errorMessage = "Error saving admin credentials: \(error.localizedDescription)"
                showAlert = true
                return
            }

            // Save Hospital Data
            hospitalRef.setData(hospitalData) { error in
                isSaving = false
                if let error = error {
                    errorMessage = "Error creating hospital: \(error.localizedDescription)"
                    showAlert = true
                } else {
                    saveSuccess = true
                    dismiss()
                }
            }
        }
    }
    
    func isValidPhoneNumber(_ number: String) -> Bool {
        let digitsOnly = number.filter { $0.isNumber }
        return digitsOnly.count >= 10
    }
}

struct LocationSearchView: View {
    @Binding var selectedLocation: String
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { _ in
                        searchForLocation()
                    }
                
                List(searchResults, id: \.self) { mapItem in
                    Button(action: {
                        if let name = mapItem.placemark.name {
                            selectedLocation = name
                            dismiss()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(mapItem.placemark.name ?? "Unknown")
                                .font(.headline)
                            Text(mapItem.placemark.title ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    func searchForLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
            } else {
                print("Location search error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}



struct HospitalAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}


#Preview {
    AddHospitalView()
}
