import SwiftUI
import FirebaseFirestore

// MARK: - Main View
struct ChangeHospitalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var isAddingHospital = false
    @State private var selectedHospital: Hospital?
    @State private var showAlert = false
    @State private var hospitals: [Hospital] = []
    var patientEmail: String  // Passed from previous screen

    var filteredHospitals: [Hospital] {
        if searchText.isEmpty {
            return hospitals
        }
        return hospitals.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // Header
                HStack {
                    Text("Change Hospital")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)
                    TextField("Search", text: $searchText)
                        .foregroundColor(.black)
                        .padding(8)
                    Spacer()
                    Button(action: { }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.black)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)

                // Hospital List
                List(filteredHospitals) { hospital in
                    PatientHospitalCard(name: hospital.name, location: hospital.location)
                        .onTapGesture {
                            selectedHospital = hospital
                            showAlert = true
                        }
                }
                .listStyle(.plain)
            }
            .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Change Hospital"),
                    message: Text("Are you sure you want to change your hospital to \(selectedHospital?.name ?? "this hospital")?"),
                    primaryButton: .default(Text("OK"), action: {
                        updateHospital()
                    }),
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                fetchHospitals()
            }
        }
    }

    // MARK: - Fetch Hospitals from Firestore
    private func fetchHospitals() {
        let db = Firestore.firestore()
        db.collection("hospitals").getDocuments { (snapshot, error) in
            if let error = error {
                print("❌ Error fetching hospitals: \(error.localizedDescription)")
                return
            }

            self.hospitals = snapshot?.documents.compactMap { document -> Hospital? in
                try? document.data(as: Hospital.self)
            } ?? []
        }
    }

    // MARK: - Update User's Hospital in Firestore
    private func updateHospital() {
        guard let newHospital = selectedHospital else { return }
        let db = Firestore.firestore()
        let usersRef = db.collection("patients")

        usersRef.whereField("email", isEqualTo: patientEmail).getDocuments { (snapshot, error) in
            if let error = error {
                print("❌ Error finding user: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("⚠️ User not found for email: \(patientEmail)")
                return
            }

            let documentID = document.documentID

            usersRef.document(documentID).updateData([
                "location": newHospital.location
            ]) { error in
                if let error = error {
                    print("❌ Failed to update hospital: \(error.localizedDescription)")
                } else {
                    print("✅ Hospital updated successfully!")
                    redirectToLogin() // ✅ Redirect to LoginView after update
                }
            }
        }
    }

    // MARK: - Redirect to LoginView without Navigation
    private func redirectToLogin() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIHostingController(rootView: LoginView())
                window.makeKeyAndVisible()
            }
        }
    }
}



struct PatientHospitalCard: View {
    let name: String
    let location: String

    var body: some View {
        HStack(spacing: 16) {
            // Hospital Icon
            Image(systemName: "building.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer() // Push everything to the left

            // Arrow Icon for selection
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}






