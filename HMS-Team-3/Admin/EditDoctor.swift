import SwiftUI
import FirebaseFirestore

struct EditDoctor: View {
    
    let hospitalId: String
    @State private var doctor: DoctorModel
    @State private var originalDoctor: DoctorModel
    @State private var isEdited = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss  // ✅ Use dismiss instead of presentationMode
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var specializations: [String]
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    /// ✅ **Custom Initializer**
    init(hospitalId: String, doctor: DoctorModel) {
        self.hospitalId = hospitalId
        _doctor = State(initialValue: doctor)
        _originalDoctor = State(initialValue: doctor)
        _firstName = State(initialValue: doctor.firstName)
        _lastName = State(initialValue: doctor.lastName)
        _specializations = State(initialValue: ([doctor.specialization, "Cardiology", "Neurology", "Pediatrics", "Orthopedics"]).removingDuplicates())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                /// **Profile Image & Edit Button**
                Section {
                    VStack {
                        Button(action: { showActionSheet = true }) {
                            VStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                }
                                Text("Edit Photo")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                /// **Doctor Details**
                Section {
                    TextField("First Name", text: $firstName)
                        .onChange(of: firstName) { _, _ in updateFullName() }
                    TextField("Last Name", text: $lastName)
                        .onChange(of: lastName) { _, _ in updateFullName() }
                    Picker("Specialization", selection: $doctor.specialization) {
                        ForEach(specializations, id: \.self) { spec in
                            Text(spec)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: doctor.specialization) { _, _ in checkForChanges() }
                }
                
                /// **Degrees**
                Section(header: Text("Degrees")) {
                    ForEach(doctor.degrees.indices, id: \.self) { index in
                        HStack {
                            Button(action: { removeDegree(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            TextField("Degree", text: $doctor.degrees[index])
                                .onChange(of: doctor.degrees[index]) { _, _ in checkForChanges() }
                        }
                    }
                    Button(action: { addNewDegree() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Degree")
                        }
                    }
                }
                
                /// **Contact Information**
                Section {
                    TextField("Phone", text: $doctor.phone)
                        .keyboardType(.phonePad)
                        .onChange(of: doctor.phone) { _, _ in checkForChanges() }
                    TextField("Email", text: $doctor.email)
                        .keyboardType(.emailAddress)
                        .onChange(of: doctor.email) { _, _ in checkForChanges() }
                    VStack(alignment: .leading) {
                        Text("Address").font(.subheadline).foregroundColor(.gray)
                        TextEditor(text: $doctor.address)
                            .frame(minHeight: 100)
                            .onChange(of: doctor.address) { _, _ in checkForChanges() }
                    }
                }
                
                /// **Delete Button**
                Section {
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete Doctor")
                            .foregroundColor(.red)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Edit Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDoctorDetails()
                    }
                    .disabled(!isEdited)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Doctor"),
                    message: Text("Are you sure you want to delete this doctor? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteDoctor()
                    },
                    secondaryButton: .cancel()
                )
            }
            
        }
    }
    
    /// ✅ **Update Full Name**
    private func updateFullName() {
        doctor.firstName = firstName
        doctor.lastName = lastName
        checkForChanges()
    }
    
    /// ✅ **Check if Doctor Details Are Edited**
    private func checkForChanges() {
        isEdited = (
            doctor.firstName != originalDoctor.firstName ||
            doctor.lastName != originalDoctor.lastName ||
            doctor.specialization != originalDoctor.specialization ||
            doctor.phone != originalDoctor.phone ||
            doctor.email != originalDoctor.email ||
            doctor.degrees != originalDoctor.degrees ||
            doctor.address != originalDoctor.address
        )
    }
    
    /// ✅ **Remove a Degree**
    private func removeDegree(at index: Int) {
        doctor.degrees.remove(at: index)
        checkForChanges()
    }
    
    /// ✅ **Add a New Degree**
    private func addNewDegree() {
        doctor.degrees.append("")
        checkForChanges()
    }
    
    /// ✅ **Save Doctor Details to Firebase**
    private func saveDoctorDetails() {
        let db = Firestore.firestore()
        let doctorRef = db.collection("doctors").document(doctor.id)
        
        let updatedData: [String: Any] = [
            "firstName": doctor.firstName,
            "lastName": doctor.lastName,
            "specialization": doctor.specialization,
            "phone": doctor.phone,
            "email": doctor.email,
            "degrees": doctor.degrees,
            "address": doctor.address
        ]
        
        doctorRef.updateData(updatedData) { error in
            if error == nil {
                originalDoctor = doctor
                isEdited = false
            }
        }
    }
    
    /// ✅ **Delete Doctor**
    /// ✅ **Delete Doctor and Navigate Back to Doctor List**
    private func deleteDoctor() {
        let db = Firestore.firestore()
        db.collection("doctors").document(doctor.id).delete { error in
            if let error = error {
                print("Error deleting doctor: \(error.localizedDescription)")
            } else {
                print("Doctor deleted successfully!")
                
                // ✅ Pop back **twice** to go back to the Doctor list
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()  // Go back to DoctorDetail
                    dismiss()  // Go back to Doctor List
//                }
            }
        }
    }
    
}

// MARK: - **Helper for Removing Duplicates**
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
