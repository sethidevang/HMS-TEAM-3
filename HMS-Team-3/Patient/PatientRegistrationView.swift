import SwiftUI
import Firebase
import MapKit

struct PatientRegistrationView: View {
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = "Select Gender"
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var locationName: String = ""

    @State private var errorMessage: String = ""
    @State private var isLoading = false
    @State private var showLocationPicker = false
    @State private var navigateToPasswordScreen = false

    let genders = ["Male", "Female", "Other"]

    var isFormValid: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        gender != "Select Gender" &&
        phoneNumber.count >= 10 &&
        email.contains("@") &&
        !locationName.isEmpty &&
        errorMessage.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                FormTextField(title: "Full Name", text: $name)
                FormTextField(title: "Age", text: $age, keyboardType: .numberPad)

                VStack (alignment:.leading,spacing:5){
                    Text("Gender")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack{
                        Text("Gender")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()

                        Picker(selection: $gender, label: Text(gender).foregroundColor(.primary)) {
                            Text("Select Gender").tag("Select Gender")
                            ForEach(genders, id: \.self) { genderOption in
                                Text(genderOption).tag(genderOption)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .frame(height: 60)
                    .background(Color(.systemBackground))


                }

                FormTextField(title: "Phone Number", text: $phoneNumber, keyboardType: .phonePad)

                // Email Field with Error Message
                VStack(alignment: .leading, spacing: 5) {
                    FormTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                        .onChange(of: email) { newValue in
                            checkIfEmailExists(newValue)
                        }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Location Picker
                Button(action: { showLocationPicker.toggle() }) {
                    HStack {
                        Text(locationName.isEmpty ? "Select Location" : locationName)
                            .foregroundColor(locationName.isEmpty ? .gray : .primary)
                        Spacer()
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }

                // Next Button
                Button(action: {
                    navigateToPasswordScreen = true
                }) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                .disabled(!isFormValid || isLoading)

                // Already have an account link
                Button("Already have an account? Login") {
                    redirectToLoginView()
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6)) // Background color set to systemGray6

            // Navigation Link to Password Setup Screen
            NavigationLink(destination: SetPasswordView(name: name, age: age, gender: gender, phoneNumber: phoneNumber, email: email, locationName: locationName), isActive: $navigateToPasswordScreen) {
                EmptyView()
            }
            .navigationTitle("Patient Registration")
            .navigationBarTitleDisplayMode(.large) // Large display mode
            .sheet(isPresented: $showLocationPicker) {
                LocationSearchViews(selectedLocationName: $locationName)
            }
            .background(Color(.systemGray6))
        }
        .background(Color(.systemGray6))
    }
 


    // 🔹 Check if email exists in other collections
    func checkIfEmailExists(_ email: String) {
        let db = Firestore.firestore()
        let collectionsToCheck = ["superAdmins", "admin_credentials", "doctor_creds", "patients"]
        var emailFound = false

        let group = DispatchGroup()

        for collection in collectionsToCheck {
            group.enter()
            db.collection(collection)
                .whereField("email", isEqualTo: email)
                .getDocuments { snapshot, _ in
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        emailFound = true
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            if emailFound {
                errorMessage = "This email is already registered in another category."
            } else {
                errorMessage = ""
            }
        }
    }
}
struct SetPasswordView: View {
    let name: String
    let age: String
    let gender: String
    let phoneNumber: String
    let email: String
    let locationName: String

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordErrorMessage = ""
    @State private var isLoading = false

    var isPasswordValid: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                SecureFormTextField(title: "Password", text: $password)
                    .onChange(of: password) { _ in validatePassword() }

                SecureFormTextField(title: "Confirm Password", text: $confirmPassword)
                    .onChange(of: confirmPassword) { _ in validatePassword() }

                if !passwordErrorMessage.isEmpty {
                    Text(passwordErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()

            Spacer()

            Button(action: registerUser) {
                Text(isLoading ? "Registering..." : "Complete Registration")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPasswordValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            .disabled(!isPasswordValid || isLoading)
            .padding()

            Spacer()
        }
        .navigationTitle("Set Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func validatePassword() {
        passwordErrorMessage = password == confirmPassword ? "" : "Passwords do not match"
    }

    private func registerUser() {
        isLoading = true
        let db = Firestore.firestore()
        let newPatientRef = db.collection("patients").document()
        let patientID = newPatientRef.documentID

        let newPatient: [String: Any] = [
            "id": patientID,
            "name": name,
            "age": age,
            "gender": gender,
            "phoneNumber": phoneNumber,
            "email": email,
            "password": password,
            "location": locationName,
            "timestamp": Timestamp()
        ]

        newPatientRef.setData(newPatient) { error in
            isLoading = false
            if error == nil {
                redirectToLoginView()
            }
        }
    }
}


// 🔹 Secure Form Text Field
struct SecureFormTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            SecureField(title, text: $text)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}



// 🔹 Location Search View
struct LocationSearchViews: View {
    @ObservedObject var viewModel = LocationSearchViewModel()
    @Binding var selectedLocationName: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a location...", text: $searchText, onEditingChanged: { _ in
                    viewModel.updateSearch(query: searchText)
                })
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                List(viewModel.searchResults, id: \.title) { result in
                    Button(action: {
                        selectedLocationName = result.title
                        presentationMode.wrappedValue.dismiss() // Close sheet
                    }) {
                        VStack(alignment: .leading) {
                            Text(result.title).font(.headline)
                            Text(result.subtitle).font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
        }
    }
}


class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    private var searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    func updateSearch(query: String) {
        searchCompleter.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed: \(error.localizedDescription)")
    }
}


// 🔹 Search Completer Delegate
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var completionHandler: (([MKLocalSearchCompletion]) -> Void)?
    
    init(completionHandler: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.completionHandler = completionHandler
    }
    
    override init() { }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completionHandler?(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed: \(error.localizedDescription)")
    }
}

    // 🔹 Redirect to Login View using Window Replacement
    func redirectToLoginView() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            window.rootViewController = UIHostingController(rootView: LoginView())
            window.makeKeyAndVisible()
        }
    }


// 🔹 Reusable Form Text Field
struct FormTextField: View {
    var title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField(title, text: $text)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
    }
}

struct PatientRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        PatientRegistrationView()
            .previewDevice("iPhone 14 Pro")  // You can specify a device if needed
            .environment(\.colorScheme, .light)  // To check the light/dark mode behavior
    }
}

