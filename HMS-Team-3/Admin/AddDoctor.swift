import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UIKit
import SwiftSMTP

struct AddDoctor: View {
    let hospitalId: String
    @State private var adminId: String = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var specialization = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var experience = ""
    @State private var medicalLicenseId = ""
    @State private var bankAccountNumber = ""
    @State private var degrees: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @State private var specializations: [String] = ["aa"]

    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    @Environment(\.presentationMode) var presentationMode

    private var isFormComplete: Bool {
        return !firstName.isEmpty &&
               !lastName.isEmpty &&
               !specialization.isEmpty &&
               !phone.isEmpty &&
               !email.isEmpty &&
               !address.isEmpty &&
               !experience.isEmpty &&
               !medicalLicenseId.isEmpty &&
               !bankAccountNumber.isEmpty &&
               !degrees.isEmpty &&
               !degrees.contains(where: { $0.isEmpty })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ImageSelector(selectedImage: $selectedImage, showImagePicker: $showImagePicker, showActionSheet: $showActionSheet, sourceType: $sourceType)
                }
                .listRowBackground(Color.clear)
                .frame(maxWidth: .infinity)

                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    Picker("Specialization", selection: $specialization) {
                        ForEach(specializations, id: \.self) { spec in
                            Text(spec)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Contact Information")) {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    VStack(alignment: .leading) {
                        Text("Address").font(.subheadline).foregroundColor(.gray)
                        TextEditor(text: $address)
                            .frame(minHeight: 100)
                    }
                }

                Section(header: Text("Degrees")) {
                    ForEach(degrees.indices, id: \.self) { index in
                        HStack {
                            Button(action: { removeDegree(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            TextField("Degree", text: $degrees[index])
                        }
                    }
                    Button(action: addNewDegree) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add degree")
                        }
                    }
                }

                Section(header: Text("Professional Details")) {
                    TextField("Experience (years)", text: $experience)
                        .keyboardType(.numberPad)
                    TextField("Medical License ID", text: $medicalLicenseId)
                }

                Section(header: Text("Bank Details")) {
                    TextField("Bank Account No.", text: $bankAccountNumber)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveDoctor()
                    }
                    .disabled(!isFormComplete)
                }
            }
            .onAppear {
                fetchAdminId()
                fetchSpecializations { fetchedSpecializations in
                        self.specializations = fetchedSpecializations
                    }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func fetchAdminId() {
        let db = Firestore.firestore()
        let hospitalRef = db.collection("hospitals").document(hospitalId)

        hospitalRef.getDocument { document, error in
            DispatchQueue.main.async {  // ✅ Fix: UI updates on the main thread
                if let document = document, document.exists, let adminId = document.data()?["adminId"] as? String {
                    self.adminId = adminId
                } else {
                    print("Admin ID not found or error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    private func saveDoctor() {
        let db = Firestore.firestore()
        let doctorId = UUID().uuidString
        let generatedPassword = generateRandomPassword()

        let doctorData: [String: Any] = [
            "doctorId": doctorId,
            "firstName": firstName,
            "lastName": lastName,
            "specialization": specialization,
            "phone": phone,
            "email": email,
            "address": address,
            "experience": experience,
            "medicalLicenseId": medicalLicenseId,
            "bankAccountNumber": bankAccountNumber,
            "degrees": degrees,
            "hospitalId": hospitalId,
            "createdBy": adminId
        ]

        let credentialsData: [String: Any] = [
            "doctorId": doctorId,
            "email": email,
            "password": generatedPassword,
            "HospitalId": hospitalId
        ]

        db.collection("doctors").document(doctorId).setData(doctorData) { error in
            DispatchQueue.main.async {  // ✅ Fix: UI updates on the main thread
                if let error = error {
                    alertMessage = "Failed to add doctor: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }

                db.collection("doctor_creds").document(doctorId).setData(credentialsData) { credError in
                    DispatchQueue.main.async {  // ✅ Fix: UI updates on the main thread
                        if let credError = credError {
                            alertMessage = "Doctor added, but failed to store credentials: \(credError.localizedDescription)"
                            showingAlert = true
                            return
                        }

                        sendEmail(to: email, password: generatedPassword)
                    }
                }
            }
        }
    }

    private func sendEmail(to email: String, password: String) {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",
            email: "sethidevangsethi@gmail.com",
            password: "pjwp uynj foxi rfov",
            port: 465,
            tlsMode: .requireTLS
        )

        let from = Mail.User(name: "Doctor", email: "sethidevangsethi@gmail.com")
        let to = Mail.User(name: "New Doctor", email: email)

        let mail = Mail(
            from: from,
            to: [to],
            subject: "Your Doctor Login Credentials",
            text: """
                  Dear Doctor,

                  Welcome to our hospital system! Below are your login credentials:

                  Email: \(email)
                  Password: \(password)

                  Please log in and change your password as soon as possible.

                  Best regards,
                  Hospital Administration
                  """
        )

        smtp.send(mail) { error in
            DispatchQueue.main.async {  // ✅ Fix: UI updates on the main thread
                if let error = error {
                    alertMessage = "Email sending failed: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    alertMessage = "Doctor added successfully! Login credentials sent."
                    showingAlert = true
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func removeDegree(at index: Int) { degrees.remove(at: index) }
    private func addNewDegree() { degrees.append("") }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

private func fetchSpecializations(completion: @escaping ([String]) -> Void) {
    let db = Firestore.firestore()
    db.collection("specializations").getDocuments { snapshot, error in
        DispatchQueue.main.async {
            if let error = error {
                print("Error fetching specializations: \(error.localizedDescription)")
                completion([])
                return
            }

            let specializations = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
            completion(specializations)
        }
    }
}



struct AddDoctor_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddDoctor(hospitalId: "sampleHospitalId")
        }
    }
}
